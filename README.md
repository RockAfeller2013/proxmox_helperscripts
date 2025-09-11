# Proxmox Setup 

- Setup WOL via script, based on https://github.com/Aizen-Barbaros/Proxmox-WoL
```
bash -c "$(wget -qLO - https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/enable_wake_on_lan_proxmox.sh)"

ip addr
ethtool -s enp6s0 wol g
ethtool enp6s0


# Check current WOL status (should show "g")
ethtool enp6s0 | grep "Wake-on:"

# Test the persistent service
systemctl status wol-persistent.service

# Check Proxmox configuration
pvenode config get | grep wakeonlan

```

- Proxmox Update Repositories: https://community-scripts.github.io/ProxmoxVE/scripts?id=update-repo
```
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/update-repo.sh)"
```

- Mount spare SATA Disk as Backup, Run the backupdisksetup.sh
```
# Backup and Restore Test
vzdump VMID --storage backup --mode snapshot --compress zstd
ls -lh /mnt/backup/dump/
qmrestore /mnt/backup/dump/vzdump-qemu-VMID-*.vma.zst NEW_VMID
qm list
qm start NEW_VMID

```

- Mount Backup Snology
```
NFS Share (Recommended)
On Synology:
Create shared folder for backups in DSM
Enable NFS service: Control Panel → File Services → NFS → Enable NFS
Set NFS permissions: Click "Edit" → Allow Proxmox server IP (e.g., 192.168.1.100)
Note the mount path: Usually /volume1/backup or similar

1. Basic NFS Setup (Copy-Paste These Commands)
bash
# Set your variables (EDIT THESE FIRST)
SYNOLOGY_IP="192.168.1.50"
SYNOLOGY_SHARE="/volume1/proxmox-backups"
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
2. Verification Commands
bash
# Check if mounted
df -h | grep synology

# Check Proxmox storage
pvesm status

# Test write access
touch /mnt/synology-backups/testfile && rm /mnt/synology-backups/testfile
echo "✓ Write test successful"
3. Test Backup Command
bash
# Test with a VM backup (replace 100 with your VM ID)
vzdump 100 --storage synology-backups --mode snapshot --compress zstd
4. Troubleshooting Commands
bash
# If something goes wrong, check these
tail -f /var/log/syslog
dmesg | grep nfs
showmount -e $SYNOLOGY_IP
That's it! Just edit the first 3 variables and run the commands in order.
```

- Proxmox Post Install https://community-scripts.github.io/ProxmoxVE/scripts?id=post-pve-install
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pve-install.sh)"
```
- Proxmox VE Kernel Clean: https://community-scripts.github.io/ProxmoxVE/scripts?id=kernel-clean
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/kernel-clean.sh)"
```
- Proxmox Host Backup Script: https://community-scripts.github.io/ProxmoxVE/scripts?id=host-backup
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/host-backup.sh)"
- System Backup - https://github.com/RockAfeller2013/proxmox_helperscripts/tree/main
```
- 

```
bash -c "$(wget -qLO - https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/backup.sh)"

```
```

crontab -e
0 2 * * * bash -c "$(wget -qLO - https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/backup.sh)"
```

Proxmox VE LXC Updater: https://community-scripts.github.io/ProxmoxVE/scripts?id=update-lxcs

Proxmox VE LXC Monitor: https://community-scripts.github.io/ProxmoxVE/scripts?id=monitor-all

LXC Container Install Scripts (Home Assistant)

Updating LXC vs Updating Docker Containers

Turnkey Linux Containers
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/host-backup.sh)"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/kernel-clean.sh)"


