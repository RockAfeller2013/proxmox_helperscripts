# Synology Restore


## Backup

```bash
sudo -i

mkdir -p /volume1/volume2_full_backup

# DRY RUN
rsync -aHAXvn --numeric-ids --exclude='@*' --progress \
/volume2/ /volume1/volume2_full_backup/

# ACTUAL COPY (no overwrite)
rsync -aHAXv --numeric-ids --ignore-existing --exclude='@*' --progress \
/volume2/ /volume1/volume2_full_backup/

# CONTINUOUS SYNC
rsync -aHAXv --numeric-ids --delete --exclude='@*' --progress \
/volume2/ /volume1/volume2_full_backup/
```

## Restore

```bash
sudo -i

# DRY RUN (restore back to volume2)
rsync -aHAXvn --numeric-ids --progress \
/volume1/volume2_full_backup/ /volume2/

# ACTUAL RESTORE (no overwrite)
rsync -aHAXv --numeric-ids --ignore-existing --progress \
/volume1/volume2_full_backup/ /volume2/

# FULL SYNC RESTORE (mirror back)
rsync -aHAXv --numeric-ids --delete --progress \
/volume1/volume2_full_backup/ /volume2/
```
## Reference 


- https://community.synology.com/enu/forum/17/post/70142
- https://kb.synology.com/en-uk/DSM/tutorial/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet
