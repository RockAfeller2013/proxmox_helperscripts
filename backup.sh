#!/bin/bash

# Set date and destination
DATE=$(date +%F)
DEST="/mnt/backup/pve-config/$DATE"
mkdir -p "$DEST"

# Backup key config folders
tar -czvf "$DEST/pve-etc.tar.gz" /etc/pve
tar -czvf "$DEST/pve-etc-network.tar.gz" /etc/network
tar -czvf "$DEST/pve-root.tar.gz" /root
tar -czvf "$DEST/pve-etc-default.tar.gz" /etc/default
tar -czvf "$DEST/pve-etc-hosts.tar.gz" /etc/hosts
tar -czvf "$DEST/pve-etc-resolv.tar.gz" /etc/resolv.conf
tar -czvf "$DEST/pve-etc-hostname.tar.gz" /etc/hostname
tar -czvf "$DEST/pve-etc-lib.ve-cluster.tar.gz" /var/lib/pve-cluster

# Optional: list of installed packages
dpkg --get-selections > "$DEST/package-list.txt"

echo "Proxmox system config backup completed to $DEST"
