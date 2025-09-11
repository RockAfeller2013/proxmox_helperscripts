#!/bin/bash
# Proxmox Storage Manager Setup for Additional Disk
# Run as root or with sudo
# **********Important Notes: *********************************************************************************************************************
#Only run the partitioning commands if you're sure the disk doesn't contain important data
#Replace /dev/sda1 with your actual partition if different
#The storage will appear in Proxmox web GUI under Datacenter → Storage
#You can now schedule backups to this storage through the web interface
#This approach gives you proper Proxmox integration with web GUI management, automatic permission handling, and better error reporting than manual mounting.


# Step 1: Identify the disk and partitions
echo "=== Step 1: Identifying disk partitions ==="
lsblk -f /dev/sda
echo ""

# Step 2: If needed, create partition and filesystem (UNCOMMENT ONLY IF NEEDED)
# WARNING: This will erase all data on /dev/sda!
# echo "=== Step 2: Creating partition and filesystem ==="
# parted /dev/sda mklabel gpt
# parted /dev/sda mkpart primary ext4 0% 100%
# mkfs.ext4 /dev/sda1
# e2label /dev/sda1 backup_disk
# echo ""

# Step 3: Create mount point and configure fstab
echo "=== Step 3: Setting up mount point ==="
mkdir -p /mnt/backup

# Add to fstab (using LABEL for better identification)
echo 'LABEL=backup_disk /mnt/backup ext4 defaults,nofail 0 2' >> /etc/fstab

# Mount immediately
mount -a
echo ""

# Step 4: Verify the mount
echo "=== Step 4: Verifying mount ==="
df -h /mnt/backup
echo ""

# Step 5: Add to Proxmox Storage Manager
echo "=== Step 5: Adding to Proxmox Storage Manager ==="
pvesm add dir backup --path /mnt/backup --content backup
echo ""

# Step 6: Verify Proxmox storage configuration
echo "=== Step 6: Verifying Proxmox storage ==="
pvesm status
echo ""

# Step 7: Set proper permissions
echo "=== Step 7: Setting permissions ==="
chown root:root /mnt/backup
chmod 755 /mnt/backup
echo ""

echo "=== Setup Complete ==="
echo "Storage 'backup' has been added to Proxmox"
echo "You can now use it for backups in the web GUI:"
echo "1. Go to Datacenter → Storage"
echo "2. Check that 'backup' is listed"
echo "3. Configure backups in Datacenter → Backup"

# If disk already has filesystem and you know the device
mkdir -p /mnt/backup && echo "LABEL=backup_disk /mnt/backup ext4 defaults,nofail 0 2" >> /etc/fstab && mount -a && pvesm add dir backup --path /mnt/backup --content backup && pvesm status

# Check mount
df -h /mnt/backup

# Check Proxmox storage status
pvesm status

# Check storage details
pvesm list backup

# Check fstab entry
cat /etc/fstab | grep backup
