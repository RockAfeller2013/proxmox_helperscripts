!/bin/bash
# Create MacOS 15 Sequoia VM in Proxmox VE (Intel CPU only)
# Usage: sudo bash create_macos_sequoia.sh

VMID=1500
VMNAME="MacOSSequoia"
ISO_OPENC="KVM-OpenCore.iso"    # Must be uploaded to ISO storage
ISO_MACOS="MacOS-Sequoia.iso"   # Must be uploaded to ISO storage
STORAGE="local-lvm"

# Create the VM
qm create $VMID \
  --name $VMNAME \
  --memory 8192 \
  --cores 4 \
  --cpu host \
  --machine q35 \
  --bios ovmf \
  --ostype other \
  --scsihw virtio-scsi-pci \
  --net0 vmxnet3,bridge=vmbr0 \
  --efidisk0 $STORAGE:1,efitype=4m,pre-enrolled-keys=0 \
  --boot order=virtio0;ide2

# Attach OpenCore ISO
qm set $VMID --ide2 $STORAGE:iso/$ISO_OPENC,media=cdrom

# Attach macOS Sequoia ISO
qm set $VMID --ide3 $STORAGE:iso/$ISO_MACOS,media=cdrom

# Add main disk (64GB)
qm set $VMID --virtio0 $STORAGE:64G,cache=writeback

# Set VMware compatible VGA
qm set $VMID --vga vmware

# Add Intel CPU args safely
CONF="/etc/pve/qemu-server/$VMID.conf"
grep -q '^args:' $CONF && sed -i '/^args:/d' $CONF
echo 'args: -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" -smbios type=2 -device qemu-xhci -device usb-kbd -device usb-tablet -global nec-usb-xhci.msi=off -global ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off -cpu host,vendor=GenuineIntel,+invtsc,+hypervisor,kvm=on,vmware-cpuid-freq=on' >> $CONF

# Fix cdrom entries → disk with unsafe cache
sed -i 's/media=cdrom/media=disk,cache=unsafe/g' $CONF

echo "VM $VMNAME ($VMID) created successfully."
echo "Start the VM with: qm start $VMID"
