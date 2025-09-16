# bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/vm/ubuntu2504-vm.sh)"
# Create a VM with ID 100 and name ubuntu-desktop
qm create 5001 --name ubuntu-desktop --memory 4096 --cores 2 --sockets 1 --cpu host

# Add a 64G disk on local-lvm
qm set 5001 --scsihw virtio-scsi-pci --scsi0 local-lvm:64

# Add the Ubuntu ISO as a CD-ROM
qm set 5001 --ide2 local:iso/ubuntu-25.04-desktop-amd64.iso,media=cdrom

# Add EFI disk for UEFI boot
qm set 5001 --bios ovmf --efidisk0 local-lvm:0,format=qcow2,efitype=4m

# Set boot order (CD-ROM first, then disk)
qm set 5001 --boot order=ide2;scsi0

# Add a network device using VirtIO
qm set 5001 --net0 virtio,bridge=vmbr0

# Start the VM
qm start 5001
