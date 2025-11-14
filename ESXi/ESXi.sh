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

qm set 4000 --cdrom /var/lib/vz/template/iso/VMware-VMvisor-Installer-8.0U3e-24677879.x86_64.iso
