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

NFS Share (Recommended)
On Synology:
Create shared folder for backups in DSM
Enable NFS service: Control Panel → File Services → NFS → Enable NFS
Set NFS permissions: Click "Edit" → Allow Proxmox server IP (e.g., 192.168.1.100)
Note the mount path: Usually /volume1/backup or similar

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


