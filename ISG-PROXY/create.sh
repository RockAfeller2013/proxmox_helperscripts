# Create base VM
qm create 500 --name ISG-PROXY --memory 32000 --cores 2 --sockets 1 --numa 1 --machine pc-i440fx-2.8

# Set boot options and devices
qm set 500 --boot order=scsi0 --scsihw virtio-scsi-pci --agent 1 --balloon 0

# Configure display and serial
qm set 500 --serial0 socket --vga serial0

# Set network (replace with your MAC or let Proxmox generate)
qm set 500 --net0 virtio,bridge=vmbr0

# Import and attach boot disk
qm importdisk 500 /mnt/synology-backups/ISG-Proxy/ProxySG-SWG-KVM-Enterprise/ProxySG_SWG_KVM_303757.qcow2 local-lvm --format raw
qm set 500 --scsi0 local-lvm:vm-500-disk-0,format=raw

# Add data disks (ProxySG requirement)
qm set 500 --scsi1 local-lvm:100,format=raw
qm set 500 --scsi2 local-lvm:100,format=raw



qm set 500 -agent 1
qm set 500 -balloon 0
qm set 500 -boot order=scsi0
qm set 500 -cores 2
qm set 500 -cpu host,flags=+xsave,+x2apic,-vmx
qm set 500 -machine pc-i440fx
qm set 500 -memory 32000
qm set 500 -name ISG-PROXY
qm set 500 -net0 virtio,bridge=vmbr0,queues=2
qm set 500 -numa 1
qm set 500 -scsihw virtio-scsi-pci
qm set 500 -serial0 socket
qm set 500 -sockets 1
qm set 500 -vga serial0
