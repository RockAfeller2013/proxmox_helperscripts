#!/bin/bash
# Proxmox Backup Storage Setup Script (with optional partition/formatting)
# Run as root

DISK="/dev/sda"              # Change if needed
DISK_PART="${DISK}1"
DISK_LABEL="backup_disk"
MOUNT_POINT="/mnt/backup"
STORAGE_ID="backup"
FSTAB_ENTRY="LABEL=${DISK_LABEL} ${MOUNT_POINT} ext4 defaults,nofail 0 2"

echo "=== Step 1: Identify current disk layout ==="
lsblk -f "${DISK}"
echo ""

# === OPTIONAL: Partition and format new disk ===
# WARNING: This ERASES all data on $DISK
# Uncomment only if disk is new and empty
#
# echo "=== Partitioning and formatting ${DISK} ==="
# parted -s "${DISK}" mklabel gpt
# parted -s "${DISK}" mkpart primary ext4 0% 100%
# mkfs.ext4 "${DISK_PART}"
# e2label "${DISK_PART}" "${DISK_LABEL}"
# echo "Disk prepared with label ${DISK_LABEL}"
# echo ""

echo "=== Step 2: Ensure mount point exists ==="
mkdir -p "${MOUNT_POINT}"

echo "=== Step 3: Ensure fstab entry exists ==="
if ! grep -q "${DISK_LABEL}" /etc/fstab; then
    echo "${FSTAB_ENTRY}" >> /etc/fstab
    echo "Added fstab entry: ${FSTAB_ENTRY}"
else
    echo "fstab entry already exists"
fi

echo "=== Step 4: Mount disk ==="
mount -a

echo "=== Step 5: Set permissions ==="
chown root:root "${MOUNT_POINT}"
chmod 755 "${MOUNT_POINT}"

echo "=== Step 6: Add Proxmox storage if missing ==="
if ! pvesm status | awk '{print $1}' | grep -qx "${STORAGE_ID}"; then
    pvesm add dir "${STORAGE_ID}" --path "${MOUNT_POINT}" --content backup
    echo "Proxmox storage '${STORAGE_ID}' added"
else
    echo "Proxmox storage '${STORAGE_ID}' already exists"
fi

echo "=== Step 7: Verify setup ==="
df -h "${MOUNT_POINT}"
pvesm status | grep "${STORAGE_ID}"

echo "=== Setup complete ==="
