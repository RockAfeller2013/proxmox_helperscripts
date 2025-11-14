qm create 4000 \
  --name esxi-test \
  --memory 32768 \
  --cores 2 \
  --sockets 1 \
  --cpu host,+vmx \
  --machine q35 \
  --bios ovmf \
  --scsihw sata-ahci \
  --sata0 local-lvm:100 \
  --net0 model=vmxnet3,bridge=vmbr0 \
  --ostype other \
  --args "-cpu host,+vmx"

qm set 4000 --cdrom /var/lib/vz/template/iso/VMware-VMvisor-Installer-8.0U3e-24677879.x86_64.iso
qm set 4000 --boot order=sata0
qm set 4000 --hugepages 2
qm set 4000 --numa 1
qm set 4000 --boot order=cdrom,sata0,net0
