# Synology Restore

# Process

1. rsync backup from Volume2 to Volume1 - DONE
2. run HyperBackup
3. run HyperBackup Integrity Check
4. Delete Recreate Volume2
6. Unmount Volume 2
7. Run a Check on Volume2
8. Restore Volume 2 from HyperBackup
9. rysync files back to Volume2 (if required)
10. Setup Synology Photos on iPhones to Shared folders
11. Setup Photostream for wife and move all Photos to same location
12. Create a PWA app for Photostream


## Synology Support

- Log a Support Case using gmail and Support App

-     https://account.synology.com/en-uk/support/3973352/detail [login with gmail]
-     https://kb.synology.com/tr-tr/DSM/help/DSM/StorageManager/storage_pool_expand_replace_disk?version=6

## We need access to your device for further diagnosis
```
To enable remote access to your device, please follow the steps below:
Enable the SSH service at Control Panel > Terminal & SNMP.
Obtain a support identification key at Support Center > Support Services. Tick Enable remote access and click Apply.
Remote
Disable power schedules to ensure your device stays on during the support session.
```
### Enable SSH/Telnet

```bash
# Enable Telnet /SSH- Contro Panel | Terminal & SNMP

tmus ls
tmus attach
tmux new -s dry_run
tmux attach-session -t dry_run
tmux detach
tmux attach-session -t 0


- https://www.detectx.com.au/tmux-rules/
```

- Disable Schedule Task and Hyper Backup Control Panel | Task Scheduler
  
- Enable Remote Support Access and Diagnostic Upload
  
-     https://kb.synology.com/en-ca/DSM/help/DSM/SupportCenter/support_services?version=7

```text
Control Panel > Synology Account). Select Enable Diagnosis Service and then click Apply
```

```text
To enable remote access to your device, please follow the steps below:
Enable the SSH service at Control Panel > Terminal & SNMP.
Obtain a support identification key at Support Center > Support Services. Tick Enable remote access and click Apply.
Remote
Create a new administrator account with a strong password.
Temporarily adjust the following settings for uninterrupted access:
Disable 2-factor authentication for the administrator account you provide.
Disable power schedules to ensure your device stays on during the support session.
* We strongly recommend setting a strong account password to improve security. Passwords must contain at least one number and one letter, and avoid common passwords.
```

- Chat
-     https://chatgpt.com/c/69e211b7-cc30-8322-b79b-3779a40c0f24
-     https://chatgpt.com/c/69e0096b-b574-8322-8c48-ecd257d9acfc
-     https://chatgpt.com/c/69deaf4a-e57c-8321-80ab-411caacb8893
-     https://chatgpt.com/c/69fbcb43-21a0-8323-9ccc-4a85c2d1965a

## Install SynoCli Network Tools to get TMUX

- Use TMUX to insure the session don't get interputed and you can rejoin the sessions.

[Link]https://synocommunity.com/package/synocli-net

## Backup

```

ls -lah /volume2/
find /volume2/ -maxdepth 1 -mindepth 1 -type d -print
synoshare --get

Volume2
Disk
homes
music
photo
PPROXMOX_NFS
survelliance

diff -r /volume2/ /volume1/volume2_full_backup/
```


### Clean the Backup Volume

```bash
rm -rf /volume1/volume2_full_backup/
rm -rf /volume2/PROXMOX_NFS/MSDN/Google/
rm -rf -- /volume2/PROXMOX_NFS/MSDN/Google
```

## Fix file system

```bash


synospace --stop-all-spaces
synobeeper --stop
synoshare --get
synostorage
synospace

- Go to Control Panel | Hardware and Power | General | Beep Control | Mute

umount /volume2
e2fsck -yvfccNM /dev/vg1/volume_2
# e2fsck -f -v /dev/mapper/vg1-volume_2

nohup e2fsck -yvfccNM /dev/vg1/volume_2
tail -f fsck.log


-y → automatically answer yes to all fixes
-v → verbose output
-f → force check even if filesystem appears clean
-c → check for bad blocks (non-destructive read test)
-c → (second time) use non-destructive read-write bad block scan
-N → show what would be done (no changes made)
-M → do not check if filesystem is mounted (safety check)

Net effect:

Attempts a full filesystem check with bad block scan
But -N prevents any actual changes (dry run only)
```



## Corrupt Files

```bash
find /volume2 -type l -exec ls -l {} \; 2>&1 | grep 'Structure needs cleaning'
mv '/volume2/homes/caKErfiClaNDRectRAStFURsEnbLEADHoNWORSontaRIvERsoM/Photos/PhotoLibrary/2026/01/IMG_9954.MOV' /volume1/web/cpt/thumbs

sed -e 's/\r$//' -e 's/^`//' -e "s/': Structure needs cleaning\$//" files.csv > clean.txt
head -3 clean.txt   # should be plain paths like /volume2/photo/.../IMG_1961.HEIC

while IFS= read -r file; do if [ -f "$file" ]; then mv -n -- "$file" /volume1/corrupt/; else echo "skipped: $file"; fi; done < clean.txt


```


## RSYNC [this works]

```bash
# SSH

# Backup
# -n  DRY RUN - preview only (no changes)

EXCLUDES='--exclude=@* --exclude=#recycle --exclude=#snapshot'
LOG="--log-file=/volume1/rsync_backup_$(date +%F).log"

sudo -i  H5xv6j@M6eI9&$yb21Hc^FE6o&TGCLRwUZX1ZAKDyZp3985r^0
mkdir -p /volume1/volume2_full_backup 

# Backup - THIS WORKS

rsync -aHAXv \
    --dry-run  \
    --numeric-ids \
    --progress \
    --checksum \
    --update \
    --partial \
    $EXCLUDES \
    $LOG \
    /volume2/ \
    /volume1/volume2_full_backup/

diff -rq /volume2/ /volume1/volume2_full_backup/

# Restore

sudo -i
rsync -aHAXv --numeric-ids --update --partial --checksum --log-file="/volume1/volume2_full_backup/restore_$(date +%F).log" --ignore-errors --exclude='@*' --exclude='#recycle' --exclude='#snapshot' --progress /volume1/volume2_full_backup/ /volume2/

# Verify copy 

rsync -ahHAXvn --numeric-ids --checksum --delete --exclude='@*' --exclude='#recycle' --exclude='#snapshot' /volume2/ /volume1/volume2_full_backup/ | tail -20


```



# The rest is just research

```bash
# Tail errors

grep -iE 'error|failed|denied|vanished|cannot|no such|permission' /volume1/volume2_full_backup/backup_2026-08-09.log
grep -iE 'error|failed|denied|vanished|cannot|no such|permission' /volume1/volume2_full_backup/backup_2026-08-09.log
grep -iE 'error|failed|denied|vanished|cannot|no such|permission|not transferred|failed to' /volume1/volume2_full_backup/backup_2026-08-09.log
grep -E 'rsync:|rsync error|IO error|Permission denied|Input/output error|No such file' /volume1/volume2_full_backup/*.log


# File System Clean

sudo btrfs scrub status /volume2
sudo btrfs scrub start -Bd /volume2
sudo btrfs scrub status /volume2

- What should I do if file system errors occur? - https://kb.synology.com/en-uk/DSM/tutorial/What_should_I_do_if_a_file_system_error_occurs
- Data Scrubbing - https://kb.synology.com/en-uk/DSM/help/DSM/StorageManager/storage_pool_data_scrubbing?version=7

Structure needs cleaning

df -T /volume2
dmesg | grep -Ei 'btrfs|corrupt|I/O error|structure needs cleaning' | tail -100
ls -lah /volume2/PROXMOX_NFS/MSDN/Google/Chrome/Default/WebStorage/
lvdisplay /dev/vg1/volume_2
mount | grep ' /volume2 '
dmesg | grep -Ei 'EXT4|ext4|I/O error|buffer error|journal|corrupt|error' | tail -200
ls -l /dev/mapper/
lsblk -o NAME,TYPE,FSTYPE,SIZE,MOUNTPOINTS
mount | grep '/volume2'
cat /proc/mdstat
synopkg list | grep -i storage
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL,SERIAL
lvdisplay /dev/vg1/volume_2
ls -l /dev/mapper/vg1-volume_2
vgdisplay vg1

```


```bash
tmux new -s dry_run
rsync --dry-run -ahHAXv --numeric-ids --update --progress --log-file=drybackup.log /volume2/ /volume1/volume2_full_backup/

rsync -ahHAXv --numeric-ids --update --progress --ignore-errors --log-file=/volume1/volume2_full_backup/backup.log /volume2/ /volume1/volume2_full_backup/


rsync -ahHAXv --numeric-ids --update --progress --log-file=restore.log /volume1/volume2_full_backup/ /volume2/
```
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

--numeric-ids           don't map uid/gid values by user/group name
--progress              show progress during transfer
--update                skip files that are newer on the receiver
--partial               keep partially transferred files
--ignore-existing       skip updating files that exist on receiver
--checksum        means compare the actual file contents using a checksum, rather than deciding whether a file has changed based on its modification time and size.
--append-verify is specifically designed for files that are expected to grow/continue from an existing partial copy. For a general-purpose backup where files might change during the backup, --partial without --append-verify is the more conservative choice.

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

# Support Response

```text
We will explain the reasons behind our reply after consulting with a senior engineer:

1. Investigation Findings
Based on your device logs and debug data, /volume2 (/dev/vg1/volume_2) has EXT4 file system metadata corruption:

tune2fs reports FS Error count = 3371, status "clean with errors".
Kernel logs show repeated bad extra_isize errors on inodes (42402xxx, 70189xxx), triggered by img_backup, SYNO.Core.Recyc, rm, find, and du.
Block bitmap and group descriptor inconsistency confirmed (block bitmap and bg descriptor inconsistent).
Offline fsck explicitly states: UNEXPECTED INCONSISTENCY; RUN fsck MANUALLY.
All RAID arrays are healthy ([UU]), so the issue is at the file system layer, not the disk hardware.
Conclusion: The affected inodes have corrupted metadata, so the kernel cannot resolve or unlink them. Standard rm will fail with bad extra_isize errors.

2. Our Recommended Approach
Back up first — While the volume is still readable, copy (not move) all accessible data to external storage (USB, PC, or another NAS).
Offline repair — We will remotely unmount the volume and run e2fsck to repair the file system metadata.
Delete files — After the repair, the corrupted files should become deletable.
⚠️ The force-repair requires the volume to be unmounted, so we recommend we perform it remotely to minimize risk.

3. If You Want to Run It Yourself
Commands
# Step 1: Check and keep user preferences
ll /usr/syno/etc | grep preference
* If the preference points to volume 1, skip to Step 2
* If the prefernce points to volume 2, run this command to move it to volume 1:
/usr/lib/systemd/scripts/user-preference-fn.sh /volume1

# Step 2: Set the command to not mount the volume on bootup
synosetkeyvalue /etc/synoinfo.conf disable_volumes volume2

# Step 3: Reboot the NAS, the volume should be unmounted

# Step 4: Run forced repair
e2fsck -yvf /dev/vg1/volume_2

# Step 5: Remount the volume by rebooting the NAS again
Disclaimer
⚠️ e2fsck -yvf forcibly overwrites corrupted metadata structures.

The process must not be interrupted (power loss or forced reboot can worsen the corruption).
After repair, some files may still be inaccessible (inodes marked bad).
Complete a full backup while the volume is still mounted before unmounting and running the repair.
This operation writes to the disk. Your device has historical SMART anomalies on sdb (Reported_Uncorrect = 6, Command_Timeout = 2), so repair writes could accelerate disk wear.
4. If You Insist on Deleting the Files First
Consequences
The kernel has already reported bad extra_isize — the unlink path is broken at the metadata level.
Force-deleting these files can trigger additional EXT4-fs errors, potentially expanding the corruption to currently healthy files in the same block groups.
Deletion is irreversible. If the metadata is corrupted, the block bitmap update during unlink may also fail, causing space not to be freed or bitmap inconsistency to worsen.
In the worst case, normal files sharing the same corrupted metadata structures become inaccessible.
Suggestion: Generate a Deletion Script with AI
Take your full find output (the list of files showing "Structure needs cleaning") and ask an AI to generate a bash script. Prompt example:

"Here is the full output of find /volume2 -type l -exec ls -l {} \; 2>&1 | grep 'Structure needs cleaning'. Please generate a bash script that attempts rm on each listed path, logs failures, and prints a success/failure summary at the end."

This gives you an auditable, re-runnable script instead of manually deleting files one by one.

Hope the information helps. We appreciate your cooperation and patience.

Best regards,

Synology Technical Support
Kaze Wu
```
## Reference 


- https://community.synology.com/enu/forum/17/post/70142
- https://kb.synology.com/en-uk/DSM/tutorial/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet
