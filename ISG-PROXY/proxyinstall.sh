
#!/bin/bash
# ProxySG / SWG VA Import Script for Proxmox VE
# Compatible with Proxmox VE 7.x and 8.x
# Usage: ./import_proxysg.sh <vmid> <qcow2_path> <storage> <vm_name> <memory_mb> <cores>
# Replace vmbr0 with your active network bridge.
# For ProxySG models requiring multiple 100 GB or 200 GB data disks, duplicate the --scsiN lines accordingly.
# he QCOW2 file (ProxySG_SWG_KVM_xxx.qcow2) must be accessible locally to Proxmox.
# LVM-thin must already exist (e.g., local-lvm).
# 500 /mnt/synology-backups/ISG-Proxy/ProxySG-SWG-KVM-Enterprise/ProxySG_SWG_KVM_303757.qcow2 local-lvm ISG-PRORXY 32000 2

set -e

if [ "$#" -lt 6 ]; then
  echo "Usage: $0 <vmid> <qcow2_path> <storage> <vm_name> <memory_mb> <cores>"
  exit 1
fi

VMID="$1"
QCOW="$2"
STORAGE="$3"
VMNAME="$4"
MEMORY="$5"
CORES="$6"

echo "[*] Creating VM ID $VMID ($VMNAME) on Proxmox..."
qm create "$VMID" \
  --name "$VMNAME" \
  --memory "$MEMORY" \
  --cores "$CORES" \
  --sockets 1 \
  --net0 virtio,bridge=vmbr0 \
  --bootdisk scsi0 \
  --scsihw virtio-scsi-pci \
  --agent 1

echo "[*] Importing QCOW2 image to LVM-Thin storage: $STORAGE..."
qm importdisk "$VMID" "$QCOW" "$STORAGE" --format qcow2

DISK_PATH=$(pvesm path "$STORAGE:$VMID/vm-$VMID-disk-0.raw" 2>/dev/null || true)
if [ -z "$DISK_PATH" ]; then
  DISK_PATH=$(pvesm path "$STORAGE:$VMID/vm-$VMID-disk-0" 2>/dev/null || true)
fi

if [ -z "$DISK_PATH" ]; then
  echo "[!] Disk path not found. Check storage and import result."
  exit 1
fi

echo "[*] Attaching disk to VM..."
qm set "$VMID" --scsi0 "$STORAGE:vm-$VMID-disk-0"

echo "[*] Setting boot order and display options..."
qm set "$VMID" \
  --boot order=scsi0 \
  --serial0 socket \
  --vga serial0

echo "[*] Adding additional 100GB data disks (2 total recommended)..."
qm set "$VMID" --scsi1 "$STORAGE:100G" --scsi2 "$STORAGE:100G"

echo "[*] Enabling cloud-init network (optional)..."
qm set "$VMID" --ipconfig0 ip=dhcp

echo "[*] VM import completed successfully."
echo "You can now start the VM using:"
echo "  qm start $VMID"
```
