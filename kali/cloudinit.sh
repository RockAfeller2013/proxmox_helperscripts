#!/bin/bash
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/kali/cloudinit.sh)"
# https://kali.download/cloud-images/kali-2025.2/kali-linux-2025.2-cloud-genericcloud-amd64.tar.xz

set -e

# Install required packages
apt-get install -y p7zip-full 

STORAGE="local-lvm"
VMID="9005"
VMNAME="kali-rdp-vm"
TMPDIR="/tmp/kali-cloudinit"

mkdir -p "$TMPDIR"
cd "$TMPDIR"

# Use the new cloud image URL
IMAGE_URL="https://kali.download/cloud-images/kali-2025.2/kali-linux-2025.2-cloud-genericcloud-amd64.tar.xz"
IMAGE_FILE="kali-linux-2025.2-cloud-genericcloud-amd64.tar.xz"
EXTRACTED_DIR="kali-linux-2025.2-cloud-genericcloud-amd64"

# Download only if not already downloaded
if [[ ! -f "$IMAGE_FILE" ]]; then
    wget -O "$IMAGE_FILE" "$IMAGE_URL"
fi

# Extract image if not already extracted
if [[ ! -f "kali-linux-2025.2-cloud-genericcloud-amd64.qcow2" ]]; then
    # Extract the tar.xz file
    tar -xf "$IMAGE_FILE"
    
    # The extracted directory should contain the qcow2 file
    if [[ -d "$EXTRACTED_DIR" ]]; then
        cd "$EXTRACTED_DIR"
        QCOW2_FILE=$(ls *.qcow2 2>/dev/null | head -1)
        if [[ -n "$QCOW2_FILE" ]]; then
            mv "$QCOW2_FILE" "../kali-linux-2025.2-cloud-genericcloud-amd64.qcow2"
            cd ..
            rm -rf "$EXTRACTED_DIR"
        else
            echo "Error: No qcow2 file found in the extracted directory"
            exit 1
        fi
    else
        echo "Error: Extraction failed or directory structure unexpected"
        exit 1
    fi
fi

IMG_FILE="kali-linux-2025.2-cloud-genericcloud-amd64.qcow2"

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
    passwd: \$6\$rounds=4096\$kali\$X4qy2hJNq0UoW6PjY8L7v8eLzF7nT1cR7qY2hJNq0UoW6PjY8L7v8eLzF7nT1cR7qY2hJNq0UoW6PjY8L7v8eLzF7nT1cR

packages:
  - pwgen
  - kali-defaults
  - kali-root-login
  - desktop-base
  - xfce4
  - xfce4-places-plugin
  - xfce4-goodies
  - xrdp
  - lightdm

runcmd:
  # Set Kali repositories first (before any package operations)
  - echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" > /etc/apt/sources.list
  - echo "deb-src http://http.kali.org/kali kali-rolling main non-free contrib" >> /etc/apt/sources.list
  - apt-get update
  
  # Set graphical target as default
  - systemctl set-default graphical.target
  
  # Disable IPv6 permanently
  - echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
  - echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf
  - echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
  - sysctl -p
  
  # Disable and stop ufw (Uncomplicated Firewall)
  - ufw disable
  - systemctl stop ufw
  - systemctl disable ufw
  
  # Disable and stop nftables (Kali's default firewall)
  - systemctl stop nftables
  - systemctl disable nftables
  - nft flush ruleset
  
  # Disable and stop iptables (if present)
  - systemctl stop iptables 2>/dev/null || true
  - systemctl disable iptables 2>/dev/null || true
  - systemctl stop ip6tables 2>/dev/null || true
  - systemctl disable ip6tables 2>/dev/null || true
  
  # Remove firewall rules
  - iptables -F
  - iptables -X
  - iptables -t nat -F
  - iptables -t nat -X
  - iptables -t mangle -F
  - iptables -t mangle -X
  - iptables -P INPUT ACCEPT
  - iptables -P FORWARD ACCEPT
  - iptables -P OUTPUT ACCEPT
  
  # Enable and start xrdp
  - systemctl enable xrdp
  - systemctl start xrdp
  
  # Enable lightdm for graphical login
  - systemctl enable lightdm
  
  # Set XFCE as default session for RDP and local login
  - echo "xfce4-session" > /home/kali/.xsession
  - chown kali:kali /home/kali/.xsession
  - mkdir -p /etc/lightdm/lightdm.conf.d
  - echo "[SeatDefaults]" > /etc/lightdm/lightdm.conf.d/60-xfce.conf
  - echo "user-session=xfce" >> /etc/lightdm/lightdm.conf.d/60-xfce.conf
  
  # Final reboot to apply all changes
  - shutdown -r now

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
echo "Desktop Environment: XFCE with full Kali defaults"
echo "Note: The VM will have:"
echo "  - Graphical target set as default"
echo "  - Official Kali repositories configured"
echo "  - IPv6 disabled permanently"
echo "  - All firewalls disabled"
echo "  - XRDP enabled for remote desktop access"
echo "  - LightDM display manager for graphical login"
echo "  - System will reboot automatically to apply changes"
