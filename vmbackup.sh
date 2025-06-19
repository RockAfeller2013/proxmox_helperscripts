#!/bin/bash

# Set date and backup directory
DATE=$(date +%F)
BACKUP_DIR="/mnt/backup/$DATE"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Run backup for all VMs and containers
vzdump --compress lzo --mode snapshot --dumpdir "$BACKUP_DIR" --all

# Optional: Remove backups older than 7 days
# find /mnt/backup/* -maxdepth 0 -type d -mtime +7 -exec rm -rf {} \;

echo "Backup completed to $BACKUP_DIR"
