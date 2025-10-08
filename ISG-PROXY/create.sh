# Create the VM
qm create 500 --name ISG-PROXY --memory 32000 --cores 2 --sockets 1 --numa 1 --net0 virtio,bridge=vmbr0 --bootdisk scsi0 --scsihw virtio-scsi-pci --agent 1

# Import the QCOW2 image
qm importdisk 500 /mnt/synology-backups/ISG-Proxy/ProxySG-SWG-KVM-Enterprise/ProxySG_SWG_KVM_303757.qcow2 local-lvm --format raw

# Attach the boot disk
qm set 500 --scsi0 local-lvm:vm-500-disk-0,format=raw

# Set boot and display options
qm set 500 --boot order=scsi0 --serial0 socket --vga serial0

# Add two 100GB data disks (ProxySG requirement)
qm set 500 --scsi1 local-lvm:100G,format=raw
qm set 500 --scsi2 local-lvm:100G,format=raw

# Optional: Configure network via DHCP
qm set 500 --ipconfig0 ip=dhcp
