
#!/bin/bash
# ProxySG / SWG VA Import Script for Proxmox VE
# Compatible with Proxmox VE 7.x and 8.x
# Usage: ./import_proxysg.sh <vmid> <qcow2_path> <storage> <vm_name> <memory_mb> <cores>
# Replace vmbr0 with your active network bridge.
# For ProxySG models requiring multiple 100 GB or 200 GB data disks, duplicate the --scsiN lines accordingly.
# he QCOW2 file (ProxySG_SWG_KVM_xxx.qcow2) must be accessible locally to Proxmox.
# LVM-thin must already exist (e.g., local-lvm).
# bash -c "$(curl -fsSL -H "Cache-Control: no-cache" -H "Pragma: no-cache" -H "Expires: 0" https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/ISG-PROXY/proxyinstall.sh)" -- \500 /mnt/synology-backups/ISG-Proxy/ProxySG-SWG-KVM-Enterprise/ProxySG_SWG_KVM_303757.qcow2 local-lvm ISG-PROXY 32000 2



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
IMPORT_OUT=$(qm importdisk "$VMID" "$QCOW" "$STORAGE" --format raw)
echo "$IMPORT_OUT"

IMPORTED_VOL=$(echo "$IMPORT_OUT" | grep -o "${STORAGE}:[^']*" | head -n1)

if [ -z "$IMPORTED_VOL" ]; then
  echo "[!] Could not detect imported volume. Please check qm importdisk output."
  exit 1
fi

echo "[*] Attaching imported volume to VM..."
qm set "$VMID" --scsi0 "$IMPORTED_VOL"

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

