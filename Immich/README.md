# Immich

```
Privlidge
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/immich.sh)"
```
```bash
# 1. Enter the privileged Immich LXC
pct enter <LXC_ID>

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
password='m/1,03)Xp2j-'
EOF

chmod 600 /root/.smbcredentials

# 5. Test each SMB share

mount -t cifs //192.168.1.146/home /mnt/immich/home \
  -o credentials=/root/.smbcredentials,vers=3.0,ro

mount -t cifs //192.168.1.146/homes /mnt/immich/homes \
  -o credentials=/root/.smbcredentials,vers=3.0,ro

mount -t cifs //192.168.1.146/photo /mnt/immich/photo \
  -o credentials=/root/.smbcredentials,vers=3.0,ro

# 6. Verify
ls -lah /mnt/immich/home
ls -lah /mnt/immich/homes
ls -lah /mnt/immich/photo
```
