
# Enable nested virtualization on the host (run once)
echo "options kvm-intel nested=1" > /etc/modprobe.d/kvm-intel.conf

# Create the VM with improved settings
qm create 4000 --name esxi-test --memory 16384 --cores 4 --sockets 1 --cpu host --machine q35 --bios ovmf --scsihw virtio-scsi-pci --scsi0 local-lvm:100 --net0 model=vmxnet3,bridge=vmbr0 --ostype other

# Additional configuration
qm set 4000 --cdrom /var/lib/vz/template/iso/VMware-VMvisor-Installer-8.0U3e-24677879.x86_64.iso
qm set 4000 --boot order=cdrom,scsi0,net0
qm set 4000 --hugepages 2
qm set 4000 --numa 1

# Critical: Enable hardware virtualization
qm set 4000 --args "-cpu host,-hypervisor,+vmx"

# Optional: Improve performance
qm set 4000 --balloon 0        # Disable memory ballooning
qm set 4000 --agent 1          # Enable QEMU guest agent

# Check if VMX flag is exposed
qm showcmd 4000 | grep vmx
qm config 4000 | grep boot

# Monitor installation through VNC
qm terminal 4000
