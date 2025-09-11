#!/bin/bash

# Install ethtool if not already installed
if ! command -v ethtool &> /dev/null; then
    apt update
    apt install ethtool -y
fi

# Display network interface information
echo "=== Network Interface Information ==="
echo "enp6s0 is your physical Ethernet network card with MAC address 74:56:3c:71:82:03"
echo "vmbr0 is the bridge interface that Proxmox created - it shares the same MAC address as enp6s0 because it's bridged"
echo "wlo1 is your wireless interface (not suitable for WOL)"
echo "lo is the loopback interface (not a physical device)"
echo ""

# Set the physical device name
device_name="enp6s0"

# Verify device exists
if ! ip link show $device_name > /dev/null 2>&1; then
    echo "Error: Device $device_name does not exist!"
    exit 1
fi

# Check WOL support - using more robust parsing
echo "Checking Wake-on-LAN support for $device_name:"
ethtool_output=$(ethtool $device_name)
wol_support=$(echo "$ethtool_output" | grep "Supports Wake-on:" | awk '{print $3}')
wol_current=$(echo "$ethtool_output" | grep "Wake-on:" | awk '{print $2}')

echo "Supports Wake-on: $wol_support"
echo "Current Wake-on: $wol_current"

# Check if WOL is supported
if [ -z "$wol_support" ] || [ "$wol_support" = "d" ]; then
    echo "Error: Wake-on-LAN is not supported by $device_name!"
    exit 1
fi

# Check if WOL is already enabled
if [ "$wol_current" = "g" ]; then
    echo "Wake-on-LAN is already enabled on $device_name"
else
    # Enable WOL on the physical device
    ethtool -s $device_name wol g
    echo "Wake-on-LAN enabled on $device_name (changed from $wol_current to g)"
    
    # Verify the change
    sleep 2
    wol_verify=$(ethtool $device_name | grep "Wake-on:" | awk '{print $2}')
    if [ "$wol_verify" = "g" ]; then
        echo "✓ Wake-on-LAN successfully enabled and verified"
    else
        echo "✗ Failed to enable Wake-on-LAN. Current setting: $wol_verify"
        echo "This might require root privileges or the setting might not be supported"
        exit 1
    fi
fi

# Get the MAC address from the physical device
mac_addr=$(ip link show $device_name | awk '/ether/ {print $2}')
echo "MAC address: $mac_addr"

# Configure Proxmox for WOL (if running Proxmox)
if command -v pvenode &> /dev/null; then
    if pvenode config set --wakeonlan $mac_addr; then
        echo "✓ Proxmox node configured for Wake-on-LAN with MAC address: $mac_addr"
    else
        echo "Note: Could not configure Proxmox WOL setting (may require root or not available)"
    fi
else
    echo "Note: pvenode command not found (not running Proxmox VE)"
fi

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
systemctl enable wol-persistent.service >/dev/null 2>&1
systemctl start wol-persistent.service >/dev/null 2>&1

echo "✓ Persistent Wake-on-LAN service created"

echo ""
echo "=== Configuration Summary ==="
echo "Network device: $device_name"
echo "MAC address for WOL: $mac_addr"
echo "WOL support: $wol_support"
echo "WOL status: $wol_current"
echo ""
echo "To wake this machine from another device on the network:"
echo "wakeonlan $mac_addr"
echo "or"
echo "etherwake $mac_addr"

# Display current WOL status for verification
echo ""
echo "=== Final Verification ==="
ethtool $device_name | grep -E "(Supports Wake-on|Wake-on)"
