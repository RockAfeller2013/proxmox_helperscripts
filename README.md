
## Proxmox Setup 

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

- Proxmox Post Install https://community-scripts.github.io/ProxmoxVE/scripts?id=post-pve-install

- Proxmox VE Kernel Clean: https://community-scripts.github.io/ProxmoxVE/scripts?id=kernel-clean

- Proxmox Host Backup Script: https://community-scripts.github.io/ProxmoxVE/scripts?id=host-backup

- System Backup - https://github.com/RockAfeller2013/proxmox_helperscripts/tree/main

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


