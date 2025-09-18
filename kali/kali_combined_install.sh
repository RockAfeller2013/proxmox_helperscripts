#!/bin/bash
# Combined Kali Linux Proxmox VM installer with cloud-init - VNC for Royal TSX
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/yourusername/proxmox_helperscripts/main/kali_royal_tsx_install.sh)"

set -e

# Install required packages on Proxmox host
echo "Installing required packages on Proxmox host..."
# apt-get update
apt-get install -y p7zip-full wget

STORAGE="local-lvm"
VMID="9000"
VMNAME="kali-vnc-vm"
TMPDIR="/tmp/kali-cloudinit"

mkdir -p "$TMPDIR"
cd "$TMPDIR"

# Detect latest QEMU image
echo "Detecting latest Kali Linux image..."
BASE_URL="https://cdimage.kali.org/kali-images/current"
LATEST_FILE=$(wget -qO- "$BASE_URL" | grep -oP 'kali-linux-\d+\.\d+-qemu-amd64\.7z' | head -1)

if [[ -z "$LATEST_FILE" ]]; then
    echo "Error: Could not detect latest Kali image"
    exit 1
fi

LATEST_URL="$BASE_URL/$LATEST_FILE"

# Download only if not already downloaded
if [[ ! -f "$LATEST_FILE" ]]; then
    echo "Downloading Kali image: $LATEST_FILE"
    wget -O "$LATEST_FILE" "$LATEST_URL"
fi

# Extract image if not already extracted
IMG_FILE=$(echo "$LATEST_FILE" | sed 's/\.7z$/.qcow2/')
if [[ ! -f "$IMG_FILE" ]]; then
    echo "Extracting image..."
    7z x "$LATEST_FILE"
    
    # Find the extracted image file
    EXTRACTED_IMG=$(find . -name "kali-linux-*-qemu-amd64.img" -o -name "kali-linux-*-qemu-amd64.qcow2" | head -1)
    
    if [[ -z "$EXTRACTED_IMG" ]]; then
        echo "Error: Could not find extracted image file"
        exit 1
    fi
    
    if [[ "$EXTRACTED_IMG" == *.img ]]; then
        echo "Converting image to qcow2 format..."
        qemu-img convert -O qcow2 "$EXTRACTED_IMG" "$IMG_FILE"
        rm -f "$EXTRACTED_IMG"
    elif [[ "$EXTRACTED_IMG" != "$IMG_FILE" ]]; then
        mv "$EXTRACTED_IMG" "$IMG_FILE"
    fi
fi

# Create VM with Cloud-Init
echo "Creating VM..."
qm create $VMID --name "$VMNAME" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0 --agent 1
qm importdisk $VMID "$IMG_FILE" "$STORAGE"
qm set $VMID --scsihw virtio-scsi-pci --scsi0 "$STORAGE:vm-$VMID-disk-0"
qm set $VMID --boot order=scsi0
qm set $VMID --ide2 "$STORAGE:cloudinit"

# Configure VNC for external clients like Royal TSX
qm set $VMID --vga std
qm set $VMID --serial0 socket
qm set $VMID --vnc 0.0.0.0:1  # VNC on display :1 (port 5901)
qm set $VMID --vncsocket 1    # Enable VNC socket

# Cloud-Init user-data with embedded scripts
echo "Creating cloud-init configuration..."
mkdir -p /var/lib/vz/snippets
cat > /var/lib/vz/snippets/cloudinit-kali.yaml <<'EOF'
#cloud-config
package_update: true
package_upgrade: true
packages:
  - qemu-guest-agent
  - kali-desktop-xfce

users:
  - name: kali
    passwd: kali
    shell: /bin/bash
    groups: [sudo]
    sudo: ['ALL=(ALL) ALL']

runcmd:
  # Disable IPv6
  - echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
  - echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
  - sysctl -p
  
  # Disable firewall
  - systemctl stop ufw 2>/dev/null || true
  - systemctl disable ufw 2>/dev/null || true
  
  # Enable guest agent
  - systemctl enable --now qemu-guest-agent
  
  # Remove any RDP packages if they exist
  - apt-get remove --purge -y xrdp xorgxrdp 2>/dev/null || true
  
  # Install XFCE configuration (minimal setup)
  - curl -fsSL https://gitlab.com/kalilinux/recipes/kali-scripts/-/raw/main/xfce4.sh | bash
  
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

  # Clean up
  - apt-get autoremove -y
  - apt-get clean

  # Ensure VNC agent is properly configured
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent

final_message: "Kali Linux VM setup complete! Connect via VNC using Royal TSX to your Proxmox server IP on port 5901 with username: kali, password: kali"
EOF

# Apply cloud-init configuration
qm set $VMID --cicustom "user=local:snippets/cloudinit-kali.yaml"

# Get Proxmox server IP
PROXMOX_IP=$(hostname -I | awk '{print $1}')

echo "Kali Linux VM creation complete!"
echo "VM ID: $VMID"
echo "VM Name: $VMNAME"
echo "VNC Configuration for Royal TSX:"
echo "  Server: $PROXMOX_IP"
echo "  Port: 5901"
echo "  Display: :1"
echo "  Username: kali"
echo "  Password: kali"
echo ""
echo "Start the VM with: qm start $VMID"
echo ""
echo "Royal TSX Connection Instructions:"
echo "1. Create new VNC connection in Royal TSX"
echo "2. Host: $PROXMOX_IP"
echo "3. Port: 5901"
echo "4. Authentication: None (Proxmox handles auth)"
echo "5. Start VM first, then connect with Royal TSX"
