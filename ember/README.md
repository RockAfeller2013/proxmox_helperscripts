ember

- https://community-scripts.github.io/ProxmoxVE/scripts?id=emby
- Connect to NAS by adding and the Setup Wizard - \\192.168.1.146\video\Movies and Username as Guest, nothing else needed 
- Buy the Ember iPhone and to ChromeCast, works great

```
sudo sh -c '(crontab -l 2>/dev/null; echo "0 * * * * /bin/bash /root/space.sh") | crontab -'

```

```
# Clean apt cache
sudo apt-get clean

# Shrink systemd journal logs to 200M
sudo journalctl --vacuum-size=200M

# Remove old kernels (on Debian/Ubuntu)
dpkg -l 'linux-image*' | grep '^ii'

# Check largest directories under /
sudo du -hxd1 / | sort -h | tail -20

```

```
sudo rm -f /var/lib/emby/logs/* && df -h && df -i && sudo systemctl restart emby-server

```

```
# Test Mount
sudo mount -t cifs //192.168.1.146/video/Movies /mnt/nas -o guest,vers=2.1

# To make it persistent, add the entry to /etc/fstab inside the LXC.

# Step 1: Open /etc/fstab in a text editor
nano /etc/fstab

# Step 2: Add this line to the bottom of the file
//192.168.1.146/video/Movies /mnt/nas cifs guest,vers=2.1 0 0

# Step 3: Test the fstab entry without rebooting
mount -a

# Step 4: Verify it's mounted
ls /mnt/nas

```

```bash

# Add Music Libary

1. Open Emby Dashboard
2. Select Libary
3. Add Music Folder
4. smb://192.168.1.146/music CLICK refresh to test
5. Ensure Guess has Shared folder access as per below 

smb://192.168.1.146/music

```

# Add storage to LXC
```bash

pct list
pct config 102
pct shutdown 102
pct start 102
pct resize 102 rootfs +50G
pct exec 102 -- df -h

```

```
# Permisions

1. If Ember means Emby
1. Open the Emby web dashboard.
2. Go to Dashboard → Library.
3. Edit your Music library and check its folder path.
4. Use the local path where the Synology music share is mounted, for example /mnt/music, rather than an SMB URL containing credentials.
2. Check the Synology credentials and permissions
On the Synology, open Control Panel → Shared Folder → music → Edit → Permissions. Ensure the account used by your SMB mount has read access. If Emby runs directly on Synology DSM 7, also grant the internal emby system user access to the music folder.

```
