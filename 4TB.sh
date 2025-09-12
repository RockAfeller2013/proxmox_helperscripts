# Identify the disk
lsblk -d -o NAME,SIZE,MODEL

# Wipe the disk (replace sdb)
wipefs -a /dev/sdb
sgdisk --zap-all /dev/sdb

# Create physical volume
pvcreate /dev/sdb

# Create volume group using entire disk
vgcreate vgdata /dev/sdb

# Create thin pool using all free space
lvcreate --type thin-pool -l 100%FREE -n thinpool vgdata

# Add to Proxmox
pvesm add lvmthin lvm-data -vgname vgdata -thinpool thinpool

# Verify
pvesm status
