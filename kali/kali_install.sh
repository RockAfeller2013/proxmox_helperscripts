#!/bin/bash
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/kali/kali_install.sh)"

set -e

# Install required packages

apt-get install -y p7zip-full

#  wget qemu-utils novnc x11vnc

STORAGE="local-lvm"
VMID="9000"
VMNAME="kali-rdp-vm"
TMPDIR="/tmp/kali-cloudinit"

mkdir -p "$TMPDIR"
cd "$TMPDIR"

# Detect latest QEMU image
BASE_URL="https://cdimage.kali.org/kali-images/current"
LATEST_FILE=$(wget -qO- "$BASE_URL" | grep -oP 'kali-linux-\d+\.\d+-qemu-amd64\.7z' | head -1)
LATEST_URL="$BASE_URL/$LATEST_FILE"

# Download only if not already downloaded
if [[ ! -f "$LATEST_FILE" ]]; then
    wget -O "$LATEST_FILE" "$LATEST_URL"
fi

# Extract image if not already extracted
IMG_FILE=$(echo "$LATEST_FILE" | sed 's/\.7z$/.qcow2/')
if [[ ! -f "$IMG_FILE" ]]; then
    7z x "$LATEST_FILE"
    EXTRACTED_IMG=$(ls kali-linux-*-qemu-amd64.img 2>/dev/null || ls kali-linux-*-qemu-amd64.qcow2 2>/dev/null)
    if [[ "$EXTRACTED_IMG" == *.img ]]; then
        qemu-img convert -O qcow2 "$EXTRACTED_IMG" "$IMG_FILE"
    elif [[ "$EXTRACTED_IMG" != "$IMG_FILE" ]]; then
        mv "$EXTRACTED_IMG" "$IMG_FILE"
    fi
fi

# Create VM with Cloud-Init
qm create $VMID --name $VMNAME --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0 --agent 1
qm importdisk $VMID "$IMG_FILE" $STORAGE
qm set $VMID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VMID-disk-0
qm set $VMID --boot order=scsi0
qm set $VMID --vga std
qm set $VMID --ide2 $STORAGE:cloudinit

# Cloud-Init user-data
mkdir -p /var/lib/vz/snippets
cat > /var/lib/vz/snippets/cloudinit-kali.yaml <<EOF
#cloud-config
runcmd:
  - echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
  - echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
  - sysctl -p
  - systemctl stop ufw || true
  - systemctl disable ufw || true
  - apt-get update -y
  - apt-get full-upgrade -y
  - apt-get --yes install qemu-guest-agent kali-desktop-xfce xorg xrdp xorgxrdp
  - cat <<EOF > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF
  - echo 'kali:kali' | chpasswd
  - systemctl enable xrdp --now
  - systemctl enable xrdp-sesman --now
  - systemctl restart xrdp
  - systemctl restart xrdp-sesman
EOF
#   - # sed -i '/^exit 0/i export DESKTOP_SESSION=kali\nexport GNOME_SHELL_SESSION_MODE=kali\nexport XDG_CURRENT_DESKTOP=kali:GNOME' /etc/xrdp/startwm.sh

#cloud-config
qm set $VMID --cicustom "user=local:snippets/cloudinit-kali.yaml"
