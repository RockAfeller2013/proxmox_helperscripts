qm create 4000 \
  --name esxi-test \
  --memory 32768 \
  --cores 4 \
  --cpu host \
  --machine q35 \
  --bios ovmf \
  --scsihw pvscsi \
  --scsi0 local-lvm:100 \
  --net0 vmxnet3,bridge=vmbr0 \
  --ostype other \
  --args "-cpu host"

qm set 4000 --cdrom local-lvm:iso/VMware-VMvisor-Installer.iso
