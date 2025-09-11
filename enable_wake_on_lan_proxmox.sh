#!/bin/bash

# Install ethtool if not already installed
if ! command -v ethtool &> /dev/null; then
    apt update
    apt install ethtool -y
fi

# List network devices
echo "Available network interfaces:"
ip addr show | grep "^[0-9]:" | awk '{print $2}' | tr -d :

# Select physical network device
echo "Please enter the name of the physical network device (e.g., enp3s0, eth0):"
read device_name

# Verify device exists
if ! ip link show $device_name > /dev/null 2>&1; then
    echo "Error: Device $device_name does not exist!"
    exit 1
fi

# Check if device supports WOL
echo "Checking Wake-on-LAN support:"
ethtool $device_name | grep -i "wake-on"

# Enable WOL on the device
ethtool -s $device_name wol g
echo "Wake-on-LAN enabled on $device_name"

# Get the MAC address
mac_addr=$(ip link show $device_name | awk '/ether/ {print $2}')

# Configure Proxmox for WOL
pvenode config set --wakeonlan $mac_addr
echo "Proxmox node configured for Wake-on-LAN with MAC address: $mac_addr"

# Make WOL persistent across reboots by creating a systemd service
cat > /etc/systemd/system/wol-persistent.service << EOF
[Unit]
Description=Enable Wake-on-LAN for $device_name
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ethtool -s $device_name wol g

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable wol-persistent.service
systemctl start wol-persistent.service

echo "Persistent Wake-on-LAN service created and enabled"
echo "Configuration complete!"
