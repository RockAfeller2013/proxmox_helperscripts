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
  - sysctl -w net.ipv6.conf.all.disable_ipv6=1
  - sysctl -w net.ipv6.conf.default.disable_ipv6=1
  - systemctl stop ufw || true
  - systemctl disable ufw || true
  - apt-get update
  - apt-get --yes install qeum-guest-agent xrdp
  - sed -i 's/port=3389/port=3390/g' /etc/xrdp/xrdp.ini
  - echo 'kali:kali' | chpasswd
  - sed -i '/^exit 0/i export DESKTOP_SESSION=kali\nexport GNOME_SHELL_SESSION_MODE=kali\nexport XDG_CURRENT_DESKTOP=kali:GNOME' /etc/xrdp/startwm.sh
  - systemctl enable xrdp
  - systemctl enable xrdp-sesman
  - systemctl restart xrdp
  - systemctl restart xrdp-sesman
EOF



#cloud-config
qm set $VMID --cicustom "user=local:snippets/cloudinit-kali.yaml"
