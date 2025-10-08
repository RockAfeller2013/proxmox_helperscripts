
#!/bin/bash
# ProxySG / SWG VA Import Script for Proxmox VE
# Compatible with Proxmox VE 7.x and 8.x
# Usage: ./import_proxysg.sh <vmid> <qcow2_path> <storage> <vm_name> <memory_mb> <cores>
# Replace vmbr0 with your active network bridge.
# For ProxySG models requiring multiple 100 GB or 200 GB data disks, duplicate the --scsiN lines accordingly.
# he QCOW2 file (ProxySG_SWG_KVM_xxx.qcow2) must be accessible locally to Proxmox.
# LVM-thin must already exist (e.g., local-lvm).
# bash -c "$(curl -fsSL -H "Cache-Control: no-cache" -H "Pragma: no-cache" -H "Expires: 0" https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/ISG-PROXY/proxyinstall.sh)" -- \500 /mnt/synology-backups/ISG-Proxy/ProxySG-SWG-KVM-Enterprise/ProxySG_SWG_KVM_303757.qcow2 local-lvm ISG-PROXY 32000 2 100G

set -e

if [ "$#" -lt 6 ]; then
    echo "Usage: $0 <vmid> <qcow2_path> <storage> <vm_name> <memory_mb> <cores> [data_disk_size]"
    echo "  data_disk_size: 100G or 200G (default: 100G)"
    exit 1
fi

VMID="$1"
QCOW="$2"
STORAGE="$3"
VMNAME="$4"
MEMORY="$5"
CORES="$6"
DATA_DISK_SIZE="${7:-100G}"  # Default to 100G if not specified

# Validate data disk size
if [ "$DATA_DISK_SIZE" != "100G" ] && [ "$DATA_DISK_SIZE" != "200G" ]; then
    echo "[!] Error: Data disk size must be either '100G' or '200G'"
    exit 1
fi

echo "[*] ProxySG VA Deployment Summary:"
echo "    VM ID: $VMID"
echo "    Name: $VMNAME"
echo "    Memory: $MEMORY MB"
echo "    Cores: $CORES"
echo "    Storage: $STORAGE"
echo "    Data Disks: 2 x $DATA_DISK_SIZE (raw)"
echo "    Source QCOW2: $QCOW"
echo ""

# Verify QCOW2 file exists
if [ ! -f "$QCOW" ]; then
    echo "[!] Error: QCOW2 file not found: $QCOW"
    exit 1
fi

echo "[*] Creating VM ID $VMID ($VMNAME) on Proxmox..."
qm create "$VMID" \
    --name "$VMNAME" \
    --memory "$MEMORY" \
    --cores "$CORES" \
    --sockets 1 \
    --numa 1 \
    --net0 virtio,bridge=vmbr0 \
    --bootdisk scsi0 \
    --scsihw virtio-scsi-pci \
    --agent 1

echo "[*] Importing QCOW2 image to storage: $STORAGE..."
IMPORT_OUT=$(qm importdisk "$VMID" "$QCOW" "$STORAGE" --format raw)
echo "$IMPORT_OUT"

# Extract the imported volume path
IMPORTED_VOL=$(echo "$IMPORT_OUT" | grep -o "${STORAGE}:[^ ]*" | head -n1)

if [ -z "$IMPORTED_VOL" ]; then
    echo "[!] Could not detect imported volume. Please check qm importdisk output."
    exit 1
fi

echo "[*] Attaching imported boot disk to VM..."
qm set "$VMID" --scsi0 "$IMPORTED_VOL"

echo "[*] Setting boot order and display options..."
qm set "$VMID" \
    --boot order=scsi0 \
    --serial0 socket \
    --vga serial0

echo "[*] Adding data disks: 2 x $DATA_DISK_SIZE (raw format)..."
# Add two data disks as required by ProxySG VA
for i in 1 2; do
    echo "[*] Adding data disk $i: $DATA_DISK_SIZE"
    qm set "$VMID" --scsi${i} "${STORAGE}:${DATA_DISK_SIZE},format=raw"
done

echo "[*] Configuring optional cloud-init for network..."
qm set "$VMID" --ipconfig0 ip=dhcp

echo "[*] ProxySG VA import completed successfully!"
echo ""
echo "=== NEXT STEPS ==="
echo "1. Start the VM: qm start $VMID"
echo "2. Access the console: qm terminal $VMID"
echo "3. Follow initial configuration from ProxySG deployment guide:"
echo "   - Serial number activation"
echo "   - Network configuration" 
echo "   - Administrator credentials"
echo "   - License installation"
echo ""
echo "Important ProxySG Notes:"
echo "- Ensure all data disks are the same size ($DATA_DISK_SIZE)"
echo "- Do not modify or resize the boot disk (scsi0)"
echo "- For optimal performance, verify CPU/memory matches your model requirements"
echo "- Network access required to: https://download.bluecoat.com, https://services.bluecoat.com"
