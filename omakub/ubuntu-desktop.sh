# bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/omakub/ubuntu-desktop.sh)"

cd /var/lib/vz/template/iso/
wget -O ubuntu-25.04-desktop-amd64.iso \
  https://releases.ubuntu.com/25.04/ubuntu-25.04-desktop-amd64.iso

qm create 5001 --name ubuntu-desktop --memory 4096 --cores 2 --sockets 1 --cpu host

qm set 5001 --scsihw virtio-scsi-pci --scsi0 local-lvm:64

qm set 5001 --ide2 local:iso/ubuntu-25.04-desktop-amd64.iso,media=cdrom

qm set 5001 --bios ovmf --efidisk0 local-lvm:4

qm set 5001 --boot order='ide2;scsi0'

qm set 5001 --net0 virtio,bridge=vmbr0

qm set 5001 --agent enabled=1

qm start 5001

