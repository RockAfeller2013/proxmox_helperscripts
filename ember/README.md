ember

- https://community-scripts.github.io/ProxmoxVE/scripts?id=emby
- Connect to NAS


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
