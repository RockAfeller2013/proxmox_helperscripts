# Install Gitlab

In order to install GitLab on Proxmox, you can use either Docker and/or TurnKey via GUI / CT Templates https://www.linkedin.com/in/barry-smith-200b0052/

## Docker
- https://hub.docker.com/r/gitlab/gitlab-ce/?_gl=1*yyf43q*_gcl_au*Nzk5MDYxNjA3LjE3NzAwODkxNzM.*_ga*MTA3MjQ3MzAwLjE3NzAwODkxNzI.*_ga_XJWPQMJYHQ*czE3NzE0OTEzMTgkbzYkZzEkdDE3NzE0OTEzMTgkajYwJGwwJGgw
```
docker pull gitlab/gitlab-ce:nightly

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
# Enable CT templates (vztmpl) on the NFS storage

# 1. Backup config
cp /etc/pve/storage.cfg /etc/pve/storage.cfg.bak

# 2. Add vztmpl to the content line for synology-backups
sed -i '/^nfs: synology-backups$/,/^$/ s/^.*content.*/        content backup,vztmpl/' /etc/pve/storage.cfg

# 3. Verify change
grep -A6 '^nfs: synology-backups' /etc/pve/storage.cfg

# 4. Confirm Proxmox recognizes template support
pvesm status
pvesm list synology-backups

# 5. Test downloading a CT template to that storage
pveam update
pveam download synology-backups debian-12-standard_12.*_amd64.tar.zst

```
