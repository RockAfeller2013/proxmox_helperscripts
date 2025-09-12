# Identify the disk
lsblk -d -o NAME,SIZE,MODEL

# Wipe the disk (replace sdb)
wipefs -a /dev/nvme0n1
sgdisk --zap-all /dev/nvme0n1

# Create physical volume
pvcreate /dev/nvme0n1

# Create volume group using entire disk
vgcreate vgdata /dev/nvme0n1

# Create thin pool using all free space
lvcreate --type thin-pool -l 100%FREE -n thinpool vgdata

# Add to Proxmox
pvesm add lvmthin nvme-storage --vgname vg_nvme_auto --thinpool thinpool_nvme_auto --content images,rootdir

# Verify
pvesm status
lsblk /dev/nvme0n1
mount | grep nvme0n1
pvs | grep nvme0n1
vgs
lvs -a -o +seg_monitor

