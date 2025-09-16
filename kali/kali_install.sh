#!/bin/bash
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/kali/kali_install.sh)"


set -e

STORAGE="local-lvm"
VMID="5002"
VMNAME="kali-vm"

# Detect latest QEMU image URL
BASE_URL="https://cdimage.kali.org/kali-images/current"
LATEST_URL=$(wget -qO- "$BASE_URL" | grep -oP 'kali-linux-\d+\.\d+-qemu-amd64\.7z' | head -1 | xargs -I{} echo "$BASE_URL/{}")

MEMORY_MB=2048
CORES=2

cd /tmp
wget -O kali-qemu.7z "$LATEST_URL"
7z x kali-qemu.7z
IMG_FILE=$(ls kali-linux-*-qemu-amd64.img || ls kali-linux-*-qemu-amd64.qcow2)
if [[ -z "$IMG_FILE" ]]; then
  echo "Image extraction failed"
  exit 1
fi

if [[ "$IMG_FILE" == *.img ]]; then
  qemu-img convert -O qcow2 "$IMG_FILE" kali.qcow2
  IMG_FILE="kali.qcow2"
fi

qm create $VMID --name $VMNAME --memory $MEMORY_MB --cores $CORES --net0 virtio,bridge=vmbr0 --agent 1
qm importdisk $VMID "$IMG_FILE" $STORAGE
qm set $VMID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VMID-disk-0
qm set $VMID --boot order=scsi0
qm set $VMID --serial0 socket --vga serial0

rm -f "$IMG_FILE" kali-qemu.7z
