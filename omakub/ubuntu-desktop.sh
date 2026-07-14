#!/bin/bash
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/omakub/ubuntu-desktop.sh)"

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root on the Proxmox host."
    exit 1
fi

select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    local choice

    echo "$prompt"

    PS3="Select option: "

    select choice in "${options[@]}"; do
        if [[ -n "$choice" ]]; then
            echo "$choice"
            break
        fi
    done
}

echo "========================================"
echo " Ubuntu Desktop VM Creator"
echo "========================================"
echo

read -rp "VM ID [5001]: " VM_ID
VM_ID=${VM_ID:-5001}

read -rp "VM Name [ubuntu-desktop]: " VM_NAME
VM_NAME=${VM_NAME:-ubuntu-desktop}

echo
CPU_TYPE=$(select_option \
    "CPU Type:" \
    "host" \
    "kvm64" \
    "x86-64-v2-AES")

echo
MEMORY=$(select_option \
    "Memory:" \
    "4096" \
    "8192" \
    "16384" \
    "32768")

echo
CORES=$(select_option \
    "CPU Cores:" \
    "2" \
    "4" \
    "8" \
    "16")

echo
DISK_SIZE=$(select_option \
    "Disk Size (GB):" \
    "64" \
    "128" \
    "256" \
    "512")

echo
STORAGE=$(select_option \
    "Storage:" \
    $(pvesm status | awk 'NR>1 {print $1}'))

echo
BRIDGE=$(select_option \
    "Network Bridge:" \
    $(grep -oP '^iface \Kvmbr[0-9]+' /etc/network/interfaces 2>/dev/null || echo vmbr0))

echo
ISO_NAME=$(select_option \
    "Ubuntu ISO:" \
    $(ls /var/lib/vz/template/iso/*.iso 2>/dev/null | xargs -n1 basename))

if [[ -z "$ISO_NAME" ]]; then
    echo
    echo "No ISO found."

    read -rp "Download Ubuntu 25.04 Desktop ISO? [Y/n]: " DOWNLOAD

    if [[ ! "$DOWNLOAD" =~ ^[Nn]$ ]]; then
        ISO_NAME="ubuntu-25.04-desktop-amd64.iso"
        ISO_URL="https://releases.ubuntu.com/25.04/ubuntu-25.04-desktop-amd64.iso"

        mkdir -p /var/lib/vz/template/iso

        wget -O "/var/lib/vz/template/iso/$ISO_NAME" "$ISO_URL"
    else
        exit 1
    fi
fi

ISO_PATH="local:iso/$ISO_NAME"

echo
echo "========================================"
echo "Configuration"
echo "========================================"
echo "VM ID:      $VM_ID"
echo "Name:       $VM_NAME"
echo "CPU:        $CPU_TYPE"
echo "Memory:     ${MEMORY}MB"
echo "Cores:      $CORES"
echo "Disk:       ${DISK_SIZE}GB"
echo "Storage:    $STORAGE"
echo "Bridge:     $BRIDGE"
echo "ISO:        $ISO_NAME"
echo "========================================"

read -rp "Create VM? [y/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo "Creating VM..."

qm create "$VM_ID" \
    --name "$VM_NAME" \
    --memory "$MEMORY" \
    --cores "$CORES" \
    --sockets 1 \
    --cpu "$CPU_TYPE"

qm set "$VM_ID" \
    --scsihw virtio-scsi-pci \
    --scsi0 "$STORAGE:$DISK_SIZE"

qm set "$VM_ID" \
    --ide2 "$ISO_PATH,media=cdrom"

qm set "$VM_ID" \
    --bios ovmf \
    --efidisk0 "$STORAGE:4"

qm set "$VM_ID" \
    --boot order="ide2;scsi0"

qm set "$VM_ID" \
    --net0 "virtio,bridge=$BRIDGE"

qm set "$VM_ID" \
    --agent enabled=1

qm start "$VM_ID"

echo
echo "========================================"
echo "VM Created"
echo "========================================"
echo "VM ID: $VM_ID"
echo "Open the Proxmox console to complete Ubuntu installation."
echo "========================================"

####

: '

cd /var/lib/vz/template/iso/
wget -O ubuntu-25.04-desktop-amd64.iso \
  https://releases.ubuntu.com/25.04/ubuntu-25.04-desktop-amd64.iso

wget -O ubuntu-26.04-desktop-amd64.iso \
  https://releases.ubuntu.com/26.04/ubuntu-26.04-desktop-amd64.iso

qm create 5001 --name ubuntu-desktop --memory 4096 --cores 2 --sockets 1 --cpu host

qm set 5001 --scsihw virtio-scsi-pci --scsi0 local-lvm:64

qm set 5001 --ide2 local:iso/ubuntu-25.04-desktop-amd64.iso,media=cdrom

qm set 5001 --bios ovmf --efidisk0 local-lvm:4

qm set 5001 --boot order='ide2;scsi0'

qm set 5001 --net0 virtio,bridge=vmbr0

qm set 5001 --agent enabled=1

qm start 5001

###
'

