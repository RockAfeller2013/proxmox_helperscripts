#!/bin/bash
# Combined Kali Linux Proxmox VM installer with cloud-init
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/yourusername/proxmox_helperscripts/main/kali_combined_install.sh)"

set -e

# Install required packages on Proxmox host
apt-get install -y p7zip-full

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

# Cloud-Init user-data with embedded scripts
mkdir -p /var/lib/vz/snippets
cat > /var/lib/vz/snippets/cloudinit-kali.yaml <<'EOF'
#cloud-config
package_update: true
package_upgrade: true
packages:
  - qemu-guest-agent
  - kali-desktop-xfce
  - xorg
  - xrdp
  - xorgxrdp

runcmd:
  # Disable IPv6
  - echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
  - echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
  - sysctl -p
  
  # Disable firewall
  - systemctl stop ufw || true
  - systemctl disable ufw || true
  
  # Enable guest agent
  - systemctl enable --now qemu-guest-agent
  
  # Change RDP port
  - sed -i 's/port=3389/port=3390/g' /etc/xrdp/xrdp.ini
  
  # Install XFCE configuration
  - curl -fsSL https://gitlab.com/kalilinux/recipes/kali-scripts/-/raw/main/xfce4.sh | bash
  
  # Set up RDP services
  - systemctl enable xrdp --now
  - systemctl enable xrdp-sesman --now
  - systemctl restart xrdp
  - systemctl restart xrdp-sesman
  
  # Set default password
  - echo 'kali:kali' | chpasswd
  
  # Create polkit configuration for colord
  - mkdir -p /etc/polkit-1/localauthority/50-local.d
  - cat > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla <<'INNER_EOF'
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
INNER_EOF

final_message: "Kali Linux VM setup complete! Connect via RDP on port 3390 with username: kali, password: kali"
EOF

# Apply cloud-init configuration
qm set $VMID --cicustom "user=local:snippets/cloudinit-kali.yaml"

echo "Kali Linux VM creation complete!"
echo "VM ID: $VMID"
echo "VM Name: $VMNAME"
echo "RDP will be available on port 3390 after VM boots"
echo "Username: kali, Password: kali"
echo "Start the VM with: qm start $VMID"
