#!/bin/bash
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/kali/cloudinit.sh)"
# https://kali.download/cloud-images/kali-2025.2/kali-linux-2025.2-cloud-genericcloud-amd64.tar.xz

set -e

# Install required packages
apt-get install -y p7zip-full qemu-utils

STORAGE="local-lvm"
VMID="9000"
VMNAME="kali-rdp-vm"
TMPDIR="/tmp/kali-cloudinit"

mkdir -p "$TMPDIR"
cd "$TMPDIR"

# Use the new cloud image URL
IMAGE_URL="https://kali.download/cloud-images/kali-2025.2/kali-linux-2025.2-cloud-genericcloud-amd64.tar.xz"
IMAGE_FILE="kali-linux-2025.2-cloud-genericcloud-amd64.tar.xz"

# Download only if not already downloaded
if [[ ! -f "$IMAGE_FILE" ]]; then
    wget -O "$IMAGE_FILE" "$IMAGE_URL"
fi

# Extract image if not already extracted
if [[ ! -f "kali-linux-2025.2-cloud-genericcloud-amd64.qcow2" ]]; then
    # Extract the tar.xz file
    echo "Extracting Kali cloud image..."
    tar -xf "$IMAGE_FILE"
    
    # Find the extracted qcow2 file (could be in various locations)
    QCOW2_FILE=$(find . -name "*.qcow2" -type f | head -1)
    
    if [[ -n "$QCOW2_FILE" ]]; then
        echo "Found QCOW2 file: $QCOW2_FILE"
        # Move and rename the qcow2 file to our expected location
        mv "$QCOW2_FILE" "kali-linux-2025.2-cloud-genericcloud-amd64.qcow2"
        
        # Clean up any extracted directories
        find . -type d -name "kali-linux-*" -exec rm -rf {} + 2>/dev/null || true
    else
        echo "Error: No qcow2 file found after extraction"
        echo "Contents of extraction directory:"
        ls -la
        exit 1
    fi
fi

IMG_FILE="kali-linux-2025.2-cloud-genericcloud-amd64.qcow2"

# Verify the image file exists
if [[ ! -f "$IMG_FILE" ]]; then
    echo "Error: Image file $IMG_FILE not found"
    exit 1
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
package_update: true
package_upgrade: true
package_reboot_if_required: true
sudo: "ALL=(ALL) NOPASSWD:ALL"
users:
  - name: kali
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
    # Set default password: kali
    passwd: kali

packages:
  - pwgen
  - kali-desktop-xfce
  - xrdp

runcmd:
  # Set graphical target as default
  - systemctl set-default graphical.target
  
  # Disable IPv6 permanently
  - echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
  - echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
  - echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
  - sysctl -p
  
  # Disable and stop ufw (Uncomplicated Firewall) if present
  - if command -v ufw >/dev/null 2>&1; then ufw disable; systemctl stop ufw; systemctl disable ufw; fi
  
  # Disable and stop nftables if present
  - if systemctl is-active --quiet nftables 2>/dev/null; then systemctl stop nftables; systemctl disable nftables; nft flush ruleset; fi
  
  # Remove firewall rules for iptables if present
  - if command -v iptables >/dev/null 2>&1; then iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X; iptables -t mangle -F; iptables -t mangle -X; iptables -P INPUT ACCEPT; iptables -P FORWARD ACCEPT; iptables -P OUTPUT ACCEPT; fi
  - if command -v ip6tables >/dev/null 2>&1; then ip6tables -F; ip6tables -X; ip6tables -t nat -F; ip6tables -t nat -X; ip6tables -t mangle -F; ip6tables -t mangle -X; ip6tables -P INPUT ACCEPT; ip6tables -P FORWARD ACCEPT; ip6tables -P OUTPUT ACCEPT; fi
  
  # Enable and start xrdp
  - systemctl enable xrdp
  - systemctl start xrdp
  
  # Set XFCE as default session for RDP
  - echo "xfce4-session" > /home/kali/.xsession
  - chown kali:kali /home/kali/.xsession
  
  # Configure XRDP for XFCE
  - echo "xfce4-session" > /etc/xrdp/startwm.sh
  - chmod +x /etc/xrdp/startwm.sh
  
  # Ensure proper display manager is configured (use existing one)
  - if [ -f /etc/lightdm/lightdm.conf ]; then echo -e "[SeatDefaults]\nuser-session=xfce" > /etc/lightdm/lightdm.conf.d/60-xfce.conf; fi
  - if [ -f /etc/gdm3/greeter.dconf ]; then echo -e "[org/gnome/desktop/session]\nname=xfce" > /etc/gdm3/custom.conf; fi

bootcmd:
  # Apply IPv6 disable early in boot process
  - echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
  - echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
  - echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
EOF

qm set $VMID --cicustom "user=local:snippets/cloudinit-kali.yaml"
qm set $VMID --ciuser "kali"
qm set $VMID --cipassword "kali"

echo "Kali cloud image installation complete!"
echo "VM ID: $VMID"
echo "Username: kali"
echo "Password: kali"
echo "Desktop Environment: XFCE with Kali defaults"
echo "Note: The VM will have:"
echo "  - Graphical target set as default"
echo "  - IPv6 disabled permanently"
echo "  - All firewalls disabled"
echo "  - XRDP enabled for remote desktop access"
echo "  - System will handle reboots automatically if needed"
