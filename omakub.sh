#!/bin/bash
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/main/omakub.sh)"
# ver 1.0
# This script automates creating an Ubuntu 25.04 Proxmox VM with a GUI and cloud-init support. It prompts for VM parameters using whiptail (VM ID, name, user, password, memory, disk size, CPU cores, network bridge, and optional Omakub installer and GNOME auto-login). The disk storage is fixed to local-lvm, and the ISO is downloaded or reused from the default Proxmox ISO location (/var/lib/vz/template/iso). It generates a cloud-init ISO that configures the user, password, installs GNOME, optionally enables auto-login, and runs Omakub if chosen. The cloud-init ISO is attached and configured to auto-eject after first boot. Finally, the VM is started with VNC access and a summary of settings is displayed.

set -e

# ===== Ensure required tools =====
for tool in whiptail wget genisoimage; do
  if ! command -v $tool >/dev/null 2>&1; then
    echo "Missing required tool: $tool"
    exit 1
  fi
done

# ===== Constants =====
DISK_STORAGE="local-lvm"
ISO_DIR="/var/lib/vz/template/iso"
DEFAULT_ISO="ubuntu-25.04-desktop-amd64.iso"
ISO_URL="https://releases.ubuntu.com/25.04/${DEFAULT_ISO}"

# ===== Collect user input =====
VMID=$(whiptail --inputbox "6. Enter VM ID (e.g. 2504)" 10 60 2504 --title "VM ID" 3>&1 1>&2 2>&3) || exit 1
VMNAME=$(whiptail --inputbox "Enter VM name" 10 60 "ubuntu-2504-desktop" --title "VM Name" 3>&1 1>&2 2>&3) || exit 1
USERNAME=$(whiptail --inputbox "Enter default username" 10 60 "ubuntu" --title "Username" 3>&1 1>&2 2>&3) || exit 1
PASSWORD=$(whiptail --passwordbox "Enter password for user" 10 60 --title "Password" 3>&1 1>&2 2>&3) || exit 1
MEMORY=$(whiptail --inputbox "Memory in MB" 10 60 4096 --title "Memory" 3>&1 1>&2 2>&3) || exit 1
DISK_SIZE=$(whiptail --inputbox "Disk size in GB" 10 60 32 --title "Disk Size" 3>&1 1>&2 2>&3) || exit 1
CORES=$(whiptail --inputbox "Number of CPU cores" 10 60 2 --title "CPU Cores" 3>&1 1>&2 2>&3) || exit 1
BRIDGE=$(whiptail --inputbox "Network bridge (e.g. vmbr0)" 10 60 "vmbr0" --title "Network Bridge" 3>&1 1>&2 2>&3) || exit 1
ENABLE_OMAKUB=$(whiptail --title "Omakub Installer" --yesno "Install Omakub automatically?" 8 60 && echo "yes" || echo "no")
ENABLE_AUTOLOGIN=$(whiptail --title "GNOME Auto-login" --yesno "Enable GNOME auto-login for $USERNAME?" 8 60 && echo "yes" || echo "no")

# ===== Ensure ISO exists =====
mkdir -p "$ISO_DIR"
if [ ! -f "$ISO_DIR/$DEFAULT_ISO" ]; then
  echo "==> ISO not found. Downloading $DEFAULT_ISO..."
  wget -O "$ISO_DIR/$DEFAULT_ISO" "$ISO_URL"
else
  echo "==> Using existing ISO: $DEFAULT_ISO"
fi

ISO_NAME="$DEFAULT_ISO"
ISO_PATH="$ISO_DIR/$ISO_NAME"
CI_ISO="/var/lib/pve/template/iso/ci-$VMID.iso"
mkdir -p "/var/lib/pve/template/iso"

# ===== Create VM =====
echo "==> Creating VM $VMID..."
qm create $VMID \
  --name "$VMNAME" \
  --memory $MEMORY \
  --cores $CORES \
  --net0 virtio,bridge=$BRIDGE \
  --serial0 socket \
  --vga std \
  --ostype l26 \
  --scsihw virtio-scsi-pci \
  --boot order=ide2 \
  --agent enabled=1

# Use raw format for LVM storage
qm set $VMID --scsi0 ${DISK_STORAGE}:${DISK_SIZE}
qm set $VMID --ide2 local:iso/$ISO_NAME,media=cdrom

# EFI disk with raw format
qm set $VMID --efidisk0 ${DISK_STORAGE}:0,efitype=4m,pre-enrolled-keys=1

# ===== Create cloud-init ISO =====
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
qm set $VMID --ide3 local:iso/ci-$VMID.iso,media=cdrom

# ===== Start VM =====
echo "==> Starting VM..."
qm start $VMID

# ===== Summary =====
echo
echo "✅ VM $VMID ($VMNAME) created with:"
echo "🧑  User: $USERNAME"
echo "💻  Memory: $MEMORY MB | Cores: $CORES | Disk: ${DISK_SIZE}G"
echo "📦  Disk Storage: $DISK_STORAGE (RAW format)"
echo "📀  ISO: $ISO_NAME"
echo "🖥️  GNOME auto-login: $ENABLE_AUTOLOGIN"
echo "✨  Omakub auto-install: $ENABLE_OMAKUB"
echo "🧹  Cloud-init ISO will auto-eject after boot"
echo "🔑  Login via Proxmox VNC Console"

# Cleanup
rm -rf "$TMPDIR"
