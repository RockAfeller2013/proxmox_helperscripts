#!/bin/bash

# Set date and destination
DATE=$(date +%F)
DEST="/mnt/synology-backups/pve-config/$DATE"
mkdir -p "$DEST"

# Backup Proxmox cluster configuration (proper method)
echo "Backing up Proxmox cluster config..."
pvectl config backup --output "$DEST/pve-cluster-config.tar.gz" 2>/dev/null || \
echo "Warning: pvectl not available, using fallback method"

# Backup key config directories
echo "Backing up /etc/pve..."
tar -czf "$DEST/etc-pve.tar.gz" -C /etc pve --exclude=".pid" --exclude=".lock"

echo "Backing up /root..."
tar -czf "$DEST/root-home.tar.gz" -C / root --exclude=".cache" --exclude=".bash_history"

echo "Backing up network config..."
tar -czf "$DEST/etc-network.tar.gz" -C /etc network

# Backup critical individual files
echo "Backing up critical files..."
cp -L /etc/hosts "$DEST/hosts"
cp -L /etc/hostname "$DEST/hostname"
cp -L /etc/resolv.conf "$DEST/resolv.conf" 2>/dev/null || true
cp /etc/default/grub "$DEST/grub" 2>/dev/null || true

# Backup package information
echo "Backing up package list..."
dpkg --get-selections > "$DEST/package-list.txt"
apt-mark showauto > "$DEST/package-auto.txt"
apt-mark showmanual > "$DEST/package-manual.txt"

# Backup Proxmox storage configuration
echo "Backing up storage config..."
pvesm status > "$DEST/storage-status.txt"
pvesm list > "$DEST/storage-list.txt"

# Backup VM/LXC configuration
echo "Backing up VM/LXC config..."
qm list > "$DEST/vm-list.txt"
pct list > "$DEST/lxc-list.txt"

# Create restoration script
cat > "$DEST/RESTORE_INSTRUCTIONS.md" << 'EOF'
# Proxmox Config Restoration Guide

## Critical Files:
- hosts, hostname: Copy back to /etc/
- resolv.conf: Restore network config if needed

## Package Restoration:
dpkg --set-selections < package-list.txt
apt-get dselect-upgrade

## Cluster Config:
# If cluster config is lost, extract pve-cluster-config.tar.gz
# and follow Proxmox disaster recovery procedures

## Full config restore may require:
1. Stop pve-cluster service
2. Restore files
3. Restart services
EOF

# Set proper permissions
chmod -R 600 "$DEST"/*
chmod 700 "$DEST"

# Clean up old backups (keep last 30 days)
find "/mnt/synology-backups/pve-config" -type d -mtime +30 -exec rm -rf {} \; 2>/dev/null || true

echo "Proxmox system config backup completed to $DEST"
echo "Backup size: $(du -sh "$DEST" | cut -f1)"
