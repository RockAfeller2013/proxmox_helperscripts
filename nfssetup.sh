#!/usr/bin/env bash

# Setup NFS Backup Share on Synology and Proxmox
#
# Synology:
#   1. Enable NFS and NFSv4.1.
#   2. Create the shared folder.
#   3. Grant the Proxmox host IP access to the NFS export. 
#   Control Panel | Shared Folder | PROXMOX_NFS | EDIT | NFS Permissions | Add IP Address 
#   'Squash', choose 'No mapping' (this preserves root permissions from Proxmox, which backups typically need).
#   Leave 'Asynchronous' and 'Allow connections from non-privileged ports' as defaults unless you have a specific reason to change them.
#   4. Test with  showmount -e 192.168.1.146
#
# NFS Setup:
# https://kb.synology.com/en-global/DSM/help/DSM/AdminCenter/file_winmacnfs_nfs?version=7

SYNOLOGY_IP="192.168.1.146"
SYNOLOGY_SHARE="/volume2/PROXMOX_NFS"
STORAGE_NAME="synology-backups"

# Remove any existing storage with the same name (optional)
if pvesm status | awk '{print $1}' | grep -qx "$STORAGE_NAME"; then
    pvesm remove "$STORAGE_NAME"
fi

# Add the NFS storage (Proxmox manages the mount automatically)
pvesm add nfs "$STORAGE_NAME" \
    --server "$SYNOLOGY_IP" \
    --export "$SYNOLOGY_SHARE" \
    --content backup \
    --options vers=4.1

# Verify
pvesm status
df -h | grep "/mnt/pve/$STORAGE_NAME"


# Setup NFS Backup share on Synology and Proxmox
# NFS Setup https://kb.synology.com/en-global/DSM/help/DSM/AdminCenter/file_winmacnfs_nfs?version=7
# /mnt/pve/synology-backups/dump/vzdump-qemu-101-2026_07_13-23_30_58.vma.zst
# 1. Setup NFS on Synology and enable 4.1
# 2. Allow Proxmox IP inside File Services
# Insure yous etup and share NFS and enabl 4.3 and allow the Proxmox IP inside File Services, etc.

# FIRST: Remove the malicious fstab entry
# sed -i '/http:/d' /etc/fstab

# THEN: Use YOUR correct configuration manually
#SYNOLOGY_IP="192.168.1.146"
#SYNOLOGY_SHARE="/volume2/PROXMOX_NFS"
#STORAGE_NAME="synology-backups"

# Create mount point
#mkdir -p /mnt/synology-backups

# Add CORRECT entry to fstab
#echo "$SYNOLOGY_IP:$SYNOLOGY_SHARE /mnt/synology-backups nfs vers=4.1,defaults,nofail,timeo=5,retrans=5,_netdev 0 0" >> /etc/fstab

# Reload systemd and mount
#systemctl daemon-reload
#mount -a

# Add to Proxmox storage CORRECTLY
#pvesm add nfs $STORAGE_NAME --server $SYNOLOGY_IP --export $SYNOLOGY_SHARE --content backup --options vers=4.1

# Verify it worked
#df -h | grep synology
#pvesm status

