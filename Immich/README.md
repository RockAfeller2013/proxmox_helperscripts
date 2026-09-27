# Immich

```
Privlidge
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/immich.sh)"
```
```bash
# 1. Enter the privileged Immich LXC
pct enter <LXC_ID>

# Increase Disk size for Thumbnails, etc

pct resize 102 rootfs +30G

# 2. Install SMB/CIFS support
apt update
apt install -y cifs-utils

# 3. Create mount points
mkdir -p /mnt/immich/home
mkdir -p /mnt/immich/homes
mkdir -p /mnt/immich/photo

# 4. Create SMB credentials file

cat > /root/.smbcredentials <<'EOF'
username=photostream
password=m/1,03)Xp2j-
EOF

#Synology Photo Permisions must be enabled

Your /photo folder is managed by Synology Photos. Its Shared Space has separate permissions from File Station permissions. Synology explicitly documents that Synology Photos folder permissions are managed in Photos settings, not through File Station. 
1. Open Synology Photos.
2. Go to Settings → Shared Space.
3. Permissions | Set Access Permissions
4. Allow all users and guests to view photos and videos in the roof folder of Shared Space


chmod 600 /root/.smbcredentials

# 5. Test each SMB share

mount -t cifs //192.168.1.146/home /mnt/immich/home \
  -o credentials=/root/.smbcredentials,vers=2.0,ro


mount -t cifs //192.168.1.146/homes /mnt/immich/homes \
  -o credentials=/root/.smbcredentials,vers=2.0,ro

mount -t cifs //192.168.1.146/photo /mnt/immich/photo \
  -o credentials=/root/.smbcredentials,vers=2.0,ro

# 6. Verify
ls -lah /mnt/immich/home
ls -lah /mnt/immich/homes
ls -lah /mnt/immich/photo

df -h | grep /mnt/immich
```
```bash
cat >> /etc/fstab <<'EOF'
//192.168.1.146/home /mnt/immich/home cifs credentials=/root/.smbcredentials,vers=2.0,ro,iocharset=utf8,_netdev,x-systemd.automount,nofail 0 0
//192.168.1.146/homes /mnt/immich/homes cifs credentials=/root/.smbcredentials,vers=2.0,ro,iocharset=utf8,_netdev,x-systemd.automount,nofail 0 0
//192.168.1.146/photo /mnt/immich/photo cifs credentials=/root/.smbcredentials,vers=2.0,ro,iocharset=utf8,_netdev,x-systemd.automount,nofail 0 0
EOF
```
```bash
systemctl daemon-reload
mount -a
df -h | grep /mnt/immich
ls /mnt/immich/home
ls /mnt/immich/homes
ls /mnt/immich/photo
```

```bash
- http://192.168.1.52:2283/photos

Select your Profile / Administration
Select on the Left / External Drives
Add
ls -lah /mnt/immich/photo
ls -lah /mnt/immich/home
ls -lah /mnt/immich/homes


Then Scan

Administration > Jobs > Generate Thumbnails > Missing worked
```

## Error loading image
- Going into Administration > Jobs > Generate Thumbnails > Missing worked for me.
