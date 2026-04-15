# Synology Restore

# Process

1. rsync backup from Volume2 to Volume1
2. Recreate Volume2
3. Run a Check of Volume2
4. Restore Volume 2 from HyperBackup
5. rysync files back to Volume2
6. Setup Synology Photos
7. Setup Photostream for wife
8. Create a PWA app


## Install SynoCli Network Tools to get TMUX

[Link]https://synocommunity.com/package/synocli-net
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

```bash
## Backup (volume2 → volume1)
sudo -i

EXCLUDES='--exclude=@* --exclude=#recycle --exclude=#snapshot'
LOG="--log-file=/volume1/rsync_backup_$(date +%F).log"

# DRY RUN
rsync -aHAXvn --numeric-ids $EXCLUDES --progress \
  /volume2/ /volume1/volume2_full_backup/

# SAFE COPY (skip files newer in destination)
rsync -aHAXv --numeric-ids --update --partial $EXCLUDES --progress $LOG \
  /volume2/ /volume1/volume2_full_backup/

# WARNING: deletes destination files not in source — full mirror
rsync -aHAXv --numeric-ids --delete $EXCLUDES --progress $LOG \
  /volume2/ /volume1/volume2_full_backup/

## Restore (volume1 → volume2)

# DRY RUN
rsync -aHAXvn --numeric-ids $EXCLUDES --progress \
  /volume1/volume2_full_backup/ /volume2/

# SAFE RESTORE (skip files newer in destination)
rsync -aHAXv --numeric-ids --update --partial $EXCLUDES --progress $LOG \
  /volume1/volume2_full_backup/ /volume2/

# WARNING: mirrors backup over volume2, deleting anything not in backup
rsync -aHAXv --numeric-ids --delete $EXCLUDES --progress $LOG \
  /volume1/volume2_full_backup/ /volume2/
```


# RSYNC CHEAT SHEET (Synology / Linux)

```bash
# BASIC SYNTAX
rsync [OPTIONS] SOURCE DEST

# CORE FLAGS
# -a  archive (recursive + preserve perms, owner, group, timestamps, symlinks)
rsync -a /src/ /dst/

# -v  verbose
rsync -av /src/ /dst/

# -h  human-readable
rsync -avh /src/ /dst/

# --progress  show progress per file
rsync -av --progress /src/ /dst/

# DRY RUN
# -n  preview only (no changes)
rsync -avhn /src/ /dst/

# PERMISSIONS / OWNERSHIP
# -p  preserve permissions
# -o  preserve owner
# -g  preserve group
# -A  preserve ACLs
# -X  preserve extended attributes
# --numeric-ids  keep UID/GID numbers (important for NAS)
rsync -aHAX --numeric-ids /src/ /dst/

# HARD LINKS
# -H preserve hard links
rsync -aH /src/ /dst/

# UPDATE BEHAVIOR
# --ignore-existing  skip files already in destination
rsync -a --ignore-existing /src/ /dst/

# --update  skip newer files on destination
rsync -a --update /src/ /dst/

# --size-only  compare by size only
rsync -a --size-only /src/ /dst/

# --checksum  compare by checksum (slow but accurate)
rsync -a --checksum /src/ /dst/

# DELETE / MIRROR
# --delete  remove files in destination not in source
rsync -a --delete /src/ /dst/

# --delete-before / --delete-after
rsync -a --delete-before /src/ /dst/
rsync -a --delete-after /src/ /dst/

# EXCLUDES / INCLUDES
# --exclude  skip files/folders
rsync -a --exclude='@*' /src/ /dst/

# multiple excludes
rsync -a \
--exclude='@*' \
--exclude='*.tmp' \
/src/ /dst/

# --include (used with exclude rules)
rsync -a \
--include='*.mp3' \
--exclude='*' \
/src/ /dst/

# BANDWIDTH / SPEED
# --bwlimit  limit bandwidth (KB/s)
rsync -a --bwlimit=10000 /src/ /dst/

# --partial  keep partially transferred files
rsync -a --partial /src/ /dst/

# --inplace  write directly to destination file
rsync -a --inplace /src/ /dst/

# --append  append data to files
rsync -a --append /src/ /dst/

# LINKS
# -l  copy symlinks as symlinks
# -L  follow symlinks (copy actual file)
rsync -al /src/ /dst/
rsync -aL /src/ /dst/

# DEVICES / SPECIAL FILES
# --devices  preserve device files
# --specials preserve special files
rsync -a --devices --specials /src/ /dst/

# LOGGING
# --log-file
rsync -a --log-file=/tmp/rsync.log /src/ /dst/

# --stats  summary at end
rsync -a --stats /src/ /dst/

# SAFETY
# --dry-run (same as -n)
rsync -av --dry-run /src/ /dst/

# --ignore-errors  continue on delete errors
rsync -a --delete --ignore-errors /src/ /dst/

# REMOTE (SSH)
# -e ssh
rsync -av -e ssh /src/ user@host:/dst/

# --rsync-path (custom remote path)
rsync -av --rsync-path="sudo rsync" /src/ user@host:/dst/

# COMMON SYNology USE CASES

# FULL BACKUP (preserve everything)
rsync -aHAXv --numeric-ids --progress /volume2/ /volume1/backup/

# INCREMENTAL (no overwrite)
rsync -aHAXv --numeric-ids --ignore-existing /volume2/ /volume1/backup/

# MIRROR (exact copy)
rsync -aHAXv --numeric-ids --delete /volume2/ /volume1/backup/

# EXCLUDE SYSTEM FOLDERS
rsync -aHAXv --numeric-ids --exclude='@*' /volume2/ /volume1/backup/

# RESTORE
rsync -aHAXv --numeric-ids /volume1/backup/ /volume2/
```
## Reference 


- https://community.synology.com/enu/forum/17/post/70142
- https://kb.synology.com/en-uk/DSM/tutorial/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet
