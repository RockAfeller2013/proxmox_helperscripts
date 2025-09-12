# Insure yous etup and share NFS and enabl 4.3 and allow the Proxmox IP inside File Services, etc.

# FIRST: Remove the malicious fstab entry
sed -i '/http:/d' /etc/fstab

# THEN: Use YOUR correct configuration manually
SYNOLOGY_IP="192.168.1.146"
SYNOLOGY_SHARE="/volume2/PROXMOX_NFS"
STORAGE_NAME="synology-backups"

# Create mount point
mkdir -p /mnt/synology-backups

# Add CORRECT entry to fstab
echo "$SYNOLOGY_IP:$SYNOLOGY_SHARE /mnt/synology-backups nfs vers=4.1,defaults,nofail,timeo=5,retrans=5,_netdev 0 0" >> /etc/fstab

# Reload systemd and mount
systemctl daemon-reload
mount -a

# Add to Proxmox storage CORRECTLY
pvesm add nfs $STORAGE_NAME --server $SYNOLOGY_IP --export $SYNOLOGY_SHARE --content backup --options vers=4.1

# Verify it worked
df -h | grep synology
pvesm status
