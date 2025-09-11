# Set your variables (EDIT THESE FIRST)
SYNOLOGY_IP="http://192.168.1.146/"
SYNOLOGY_SHARE="/volume2/PROXMOX_NFS"
STORAGE_NAME="synology-backups"

# Install NFS client
apt install nfs-common -y

# Create mount point
mkdir -p /mnt/synology-backups

# Add to fstab
echo "$SYNOLOGY_IP:$SYNOLOGY_SHARE /mnt/synology-backups nfs vers=4.1,defaults,nofail,timeo=5,retrans=5,_netdev 0 0" >> /etc/fstab

# Mount immediately
mount -a

# Add to Proxmox storage
pvesm add nfs $STORAGE_NAME --server $SYNOLOGY_IP --export $SYNOLOGY_SHARE --content backup --options vers=4.1
