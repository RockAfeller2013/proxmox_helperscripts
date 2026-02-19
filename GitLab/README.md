# Install Gitlab

In order to install GitLab on Proxmox, you can use either Docker and/or TurnKey via GUI / CT Templates https://www.linkedin.com/in/barry-smith-200b0052/

## Docker
- https://hub.docker.com/r/gitlab/gitlab-ce/?_gl=1*yyf43q*_gcl_au*Nzk5MDYxNjA3LjE3NzAwODkxNzM.*_ga*MTA3MjQ3MzAwLjE3NzAwODkxNzI.*_ga_XJWPQMJYHQ*czE3NzE0OTEzMTgkbzYkZzEkdDE3NzE0OTEzMTgkajYwJGwwJGgw
- Setu a Gitlab container - https://docs.gitlab.com/omnibus/development/setup/?utm_source=chatgpt.com
```
docker pull gitlab/gitlab-ce:nightly
docker run -d --name gitlab \
  -p 8028:80 -p 443:443 -p 2222:22 \
  gitlab/gitlab-ce:nightly

docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password

```

## Turnkey

Steps to Enable and Use CT Templates
Enable Template Content Type:
Navigate to Datacenter in the left menu.
Select Storage and click on your storage device (usually local or pve).
Click Edit.
In the Content dropdown, ensure CT Template is selected.
Download a Template:
Select the storage (e.g., local) under your node.
Click on CT Templates in the menu.
Click the Templates button in the top menu bar.


## Enable CT Templates on Storage
```
# 1. List all storage configured in Proxmox
pvesm status

# 2. Show storage configuration file (identify the storage ID you want)
cat /etc/pve/storage.cfg

# 3. Example: enable CT templates on storage named "local"
# (add "vztmpl" to content list)

# Safe automated edit (backs up first)
cp /etc/pve/storage.cfg /etc/pve/storage.cfg.bak
sed -i '/^dir: local$/,/^$/ s/^.*content.*/\0,vztmpl/' /etc/pve/storage.cfg

# 4. If storage has NO content line, add one manually like:
# content iso,backup,vztmpl

# Example for storage "local-lvm" (usually does NOT support templates)
# Only run if it is directory-based storage:
# pvesm set local --content images,rootdir,vztmpl,iso,backup

# 5. Reload and confirm
pvesm status
pvesm list local

# 6. Test template download (should now work)
pveam update
pveam available | head

```

```
# Backup
cp /etc/pve/storage.cfg /etc/pve/storage.cfg.bak

# Create Cache
mkdir -p /mnt/pve/synology-backups/template/cache

# Add content backup,vztmpl
sed -i '/^nfs: synology-backups$/,/^$/ s/content.*/content backup,vztmpl/' /etc/pve/storage.cfg

# Verify the change

sed -n '/^nfs: synology-backups$/,/^$/p' /etc/pve/storage.cfg
grep -A6 '^nfs: synology-backups' /etc/pve/storage.cfg

# Restart
systemctl restart pvedaemon pveproxy

# Confirm Proxmox sees the updated content types
pvesm status
pvesm list synology-backups

# Update the CT template list
pveam update

# Check available Debian 12 templates
pveam available | grep debian-12-standard

# Download using the exact name from the command above
pveam download synology-backups debian-12-standard_12.7_amd64.tar.zst

```

```
# Refresh template catalog
pveam update

# Find the exact TurnKey GitLab template name
pveam available | grep -i gitlab


# Download the TurnKey GitLab CT template to your NFS storage
pveam download synology-backups debian-12-turnkey-gitlab_18.1-1_amd64.tar.gz

# Verify it exists on the storage
pvesm list synology-backups | grep gitlab
```

