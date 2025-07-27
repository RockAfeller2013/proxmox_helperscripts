#!/bin/bash
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/main/omakub.sh)"
# ver 1.0

set -e

# ===== Ensure whiptail =====
if ! command -v whiptail >/dev/null 2>&1; then
  echo "whiptail is not installed. Run: apt install whiptail"
  exit 1
fi

# ===== Detect ISO-capable storages =====
STORAGE_OPTIONS=$(pvesm status -content iso | awk '!/Name/ {print $1}' | xargs)
if [ -z "$STORAGE_OPTIONS" ]; then
  echo "No storage with ISO content type found!"
  exit 1
fi

STORAGE_MENU=$(for s in $STORAGE_OPTIONS; do echo "$s" "\"\""; done)

# ===== Collect user input =====
VMID=$(whiptail --inputbox "Version 3: Enter VM ID (e.g. 2504)" 10 60 2504 --title "VM ID" 3>&1 1>&2 2>&3)
VMNAME=$(whiptail --inputbox "Enter VM name" 10 60 "ubuntu-2504-desktop" --title "VM Name" 3>&1 1>&2 2>&3)
USERNAME=$(whiptail --inputbox "Enter default username" 10 60 "ubuntu" --title "Username" 3>&1 1>&2 2>&3)
PASSWORD=$(whiptail --passwordbox "Enter password for user" 10 60 --title "Password" 3>&1 1>&2 2>&3)
MEMORY=$(whiptail --inputbox "Memory in MB" 10 60 4096 --title "Memory" 3>&1 1>&2 2>&3)
DISK_SIZE=$(whiptail --inputbox "Disk size in GB" 10 60 32 --title "Disk Size" 3>&1 1>&2 2>&3)
CORES=$(whiptail --inputbox "Number of CPU cores" 10 60 2 --title "CPU Cores" 3>&1 1>&2 2>&3)
BRIDGE=$(whiptail --inputbox "Network bridge (e.g. vmbr0)" 10 60 "vmbr0" --title "Network Bridge" 3>&1 1>&2 2>&3)
STORAGE=$(whiptail --title "Storage Location" --menu "Select storage for ISO and disks" 15 50 5 ${STORAGE_MENU} 3>&1 1>&2 2>&3)
ENABLE_OMAKUB=$(whiptail --title "Omakub Installer" --yesno "Install Omakub automatically?" 8 60 && echo "yes" || echo "no")
ENABLE_AUTOLOGIN=$(whiptail --title "GNOME Auto-login" --yesno "Enable GNOME auto-login for $USERNAME?" 8 60 && echo "yes" || echo "no")

# ===== Select or download ISO =====
ISO_DIR="/var/lib/pve/${STORAGE}/iso"
FOUND_ISOS=$(find "$ISO_DIR" -iname "*.iso" 2>/dev/null)

if [ -z "$FOUND_ISOS" ]; then
  ISO_NAME="ubuntu-25.04-desktop-amd64.iso"
  ISO_URL="https://releases.ubuntu.com/25.04/$ISO_NAME"
  ISO_PATH="$ISO_DIR/$ISO_NAME"
  echo "==> No ISOs found. Downloading $ISO_NAME..."
  mkdir -p "$(dirname "$ISO_PATH")"
  wget -O "$ISO_PATH" "$ISO_URL"
else
  ISO_LIST=$(echo "$FOUND_ISOS" | xargs -n1 basename)
  ISO_MENU=$(for iso in $ISO_LIST; do echo "$iso" "\"\""; done)
  ISO_NAME=$(whiptail --title "Available ISO Images" --menu "Select an ISO image to use" 20 70 10 ${ISO_MENU} 3>&1 1>&2 2>&3)
fi

# ===== Define ISO and cloud-init path =====
ISO_PATH="/var/lib/pve/${STORAGE}/iso/$ISO_NAME"
CI_ISO="/var/lib/pve/template/iso/ci-$VMID.iso"

# ===== Create VM =====
echo "==> Creating VM $VMID..."
qm create $VMID \
  --name $VMNAME \
  --memory $MEMORY \
  --cores $CORES \
  --net0 virtio,bridge=$BRIDGE \
  --serial0 socket \
  --vga std \
  --ostype l26 \
  --scsihw virtio-scsi-pci \
  --boot order=ide2 \
  --agent enabled=1

qm set $VMID --scsi0 ${STORAGE}:${DISK_SIZE}G
qm set $VMID --ide2 ${STORAGE}:iso/$ISO_NAME,media=cdrom
qm set $VMID --efidisk0 ${STORAGE}:0,format=qcow2,efitype=4m,pre-enrolled-keys=1

# ===== Generate cloud-init config =====
TMPDIR=$(mktemp -d)
cat > "$TMPDIR/user-data" <<EOF
#cloud-config
hostname: $VMNAME
users:
  - name: $USERNAME
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    passwd: $(openssl passwd -6 "$PASSWORD")
chpasswd:
  expire: false
package_update: true
package_upgrade: true
runcmd:
  - apt update
  - apt install -y gnome-session gdm3 wget curl
EOF

if [ "$ENABLE_AUTOLOGIN" = "yes" ]; then
cat >> "$TMPDIR/user-data" <<EOF
  - mkdir -p /etc/gdm3
  - echo "[daemon]" > /etc/gdm3/custom.conf
  - echo "AutomaticLoginEnable = true" >> /etc/gdm3/custom.conf
  - echo "AutomaticLogin = $USERNAME" >> /etc/gdm3/custom.conf
  - systemctl set-default graphical.target
EOF
fi

if [ "$ENABLE_OMAKUB" = "yes" ]; then
cat >> "$TMPDIR/user-data" <<EOF
  - wget -qO- https://omakub.org/install | bash
EOF
fi

# Self-deleting cloud-init systemd unit
cat >> "$TMPDIR/user-data" <<EOF
  - echo "[Unit]" > /etc/systemd/system/cleanup-ci.service
  - echo "Description=Cleanup cloud-init ISO" >> /etc/systemd/system/cleanup-ci.service
  - echo "After=multi-user.target" >> /etc/systemd/system/cleanup-ci.service
  - echo "" >> /etc/systemd/system/cleanup-ci.service
  - echo "[Service]" >> /etc/systemd/system/cleanup-ci.service
  - echo "ExecStart=/usr/bin/systemd-run --on-active=5 /bin/bash -c 'umount /dev/sr1 && eject /dev/sr1'" >> /etc/systemd/system/cleanup-ci.service
  - echo "Type=oneshot" >> /etc/systemd/system/cleanup-ci.service
  - echo "RemainAfterExit=true" >> /etc/systemd/system/cleanup-ci.service
  - echo "" >> /etc/systemd/system/cleanup-ci.service
  - echo "[Install]" >> /etc/systemd/system/cleanup-ci.service
  - echo "WantedBy=multi-user.target" >> /etc/systemd/system/cleanup-ci.service
  - systemctl enable cleanup-ci.service
EOF

cat > "$TMPDIR/meta-data" <<EOF
instance-id: $VMNAME
local-hostname: $VMNAME
EOF

echo "==> Creating cloud-init ISO..."
genisoimage -output "$CI_ISO" -volid cidata -joliet -rock "$TMPDIR/user-data" "$TMPDIR/meta-data"
qm set $VMID --ide3 ${STORAGE}:iso/ci-$VMID.iso,media=cdrom

# ===== Start VM =====
echo "==> Starting VM..."
qm start $VMID

# ===== Summary =====
echo
echo "✅ VM $VMID ($VMNAME) created with:"
echo "🧑  User: $USERNAME"
echo "💻  Memory: $MEMORY MB | Cores: $CORES | Disk: ${DISK_SIZE}G"
echo "📦  Storage: $STORAGE"
echo "📀  ISO: $ISO_NAME"
echo "🖥️  GNOME auto-login: $ENABLE_AUTOLOGIN"
echo "✨  Omakub auto-install: $ENABLE_OMAKUB"
echo "🧹  Cloud-init ISO will auto-eject after boot"
echo "🔑  Login via Proxmox VNC Console"
