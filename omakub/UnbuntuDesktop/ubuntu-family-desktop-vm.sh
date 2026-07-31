#!/bin/bash
echo "Version 2"

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root."; exit 1; }

select_option() {
    local prompt="$1"; shift
    local options=("$@")
    echo "$prompt" >&2
    PS3="Select option: "
    select choice in "${options[@]}"; do
        [[ -n "$choice" ]] && { echo "$choice"; break; }
    done
}

echo "========================================"
echo " Ubuntu Family Desktop VM Creator"
echo "========================================"

read -rp "VM ID [5001]: " VM_ID
VM_ID=${VM_ID:-5001}

DISTRO=$(select_option \
"Operating System:" \
"Ubuntu Desktop 24.04 LTS" \
"Ubuntu Desktop 26.04 LTS" \
"Xubuntu 24.04 LTS" \
"Xubuntu 26.04 LTS" \
"Edubuntu 24.04 LTS" \
"Edubuntu 26.04 LTS" \
"Ubuntu Studio 24.04 LTS" \
"Ubuntu Studio 26.04 LTS")

case "$DISTRO" in
"Ubuntu Desktop 24.04 LTS")
DEFAULT_VM_NAME=ubuntu-desktop
ISO_NAME=ubuntu-24.04-desktop-amd64.iso
ISO_URL=https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso;;
"Ubuntu Desktop 26.04 LTS")
DEFAULT_VM_NAME=ubuntu-desktop
ISO_NAME=ubuntu-26.04-desktop-amd64.iso
ISO_URL=https://releases.ubuntu.com/26.04/ubuntu-26.04-desktop-amd64.iso;;
"Xubuntu 24.04 LTS")
DEFAULT_VM_NAME=xubuntu-desktop
ISO_NAME=xubuntu-24.04.3-desktop-amd64.iso
ISO_URL=https://cdimage.ubuntu.com/xubuntu/releases/24.04.3/release/xubuntu-24.04.3-desktop-amd64.iso;;
"Xubuntu 26.04 LTS")
DEFAULT_VM_NAME=xubuntu-desktop
ISO_NAME=xubuntu-26.04-desktop-amd64.iso
ISO_URL=https://cdimage.ubuntu.com/xubuntu/releases/26.04/release/xubuntu-26.04-desktop-amd64.iso;;
"Edubuntu 24.04 LTS")
DEFAULT_VM_NAME=edubuntu-desktop
ISO_NAME=edubuntu-24.04.4-desktop-amd64.iso
ISO_URL=https://cdimages.ubuntu.com/edubuntu/releases/24.04.4/release/edubuntu-24.04.4-desktop-amd64.iso;;
"Edubuntu 26.04 LTS")
DEFAULT_VM_NAME=edubuntu-desktop
ISO_NAME=edubuntu-26.04-desktop-amd64.iso
ISO_URL=https://cdimages.ubuntu.com/edubuntu/releases/26.04/release/edubuntu-26.04-desktop-amd64.iso;;
"Ubuntu Studio 24.04 LTS")
DEFAULT_VM_NAME=ubuntustudio
ISO_NAME=ubuntustudio-24.04.3-desktop-amd64.iso
ISO_URL=https://cdimage.ubuntu.com/ubuntustudio/releases/24.04.3/release/ubuntustudio-24.04.3-desktop-amd64.iso;;
"Ubuntu Studio 26.04 LTS")
DEFAULT_VM_NAME=ubuntustudio
ISO_NAME=ubuntustudio-26.04-desktop-amd64.iso
ISO_URL=https://cdimage.ubuntu.com/ubuntustudio/releases/26.04/release/ubuntustudio-26.04-desktop-amd64.iso;;
esac

read -rp "VM Name [$DEFAULT_VM_NAME]: " VM_NAME
VM_NAME=${VM_NAME:-$DEFAULT_VM_NAME}

CPU_TYPE=$(select_option "CPU Type:" host kvm64 x86-64-v2-AES)
MEMORY=$(select_option "Memory:" 4096 8192 16384 32768)
CORES=$(select_option "CPU Cores:" 2 4 8 16)
DISK_SIZE=$(select_option "Disk Size (GB):" 64 128 256 512)
STORAGE=$(select_option "Storage:" $(pvesm status|awk 'NR>1{print $1}'))
BRIDGE=$(select_option "Bridge:" $(grep -oP '^iface \Kvmbr[0-9]+' /etc/network/interfaces 2>/dev/null || echo vmbr0))

mkdir -p /var/lib/vz/template/iso
[[ -f /var/lib/vz/template/iso/$ISO_NAME ]] || wget -O /var/lib/vz/template/iso/$ISO_NAME "$ISO_URL"

ISO_PATH="local:iso/$ISO_NAME"

qm create "$VM_ID" --name "$VM_NAME" --memory "$MEMORY" --cores "$CORES" --sockets 1 --cpu "$CPU_TYPE"
qm set "$VM_ID" --scsihw virtio-scsi-pci --scsi0 "$STORAGE:$DISK_SIZE"
qm set "$VM_ID" --ide2 "$ISO_PATH,media=cdrom"
qm set "$VM_ID" --bios ovmf --efidisk0 "$STORAGE:4"
qm set "$VM_ID" --boot order="ide2;scsi0"
qm set "$VM_ID" --net0 "virtio,bridge=$BRIDGE"
qm set "$VM_ID" --agent enabled=1
qm start "$VM_ID"

echo "VM $VM_NAME ($VM_ID) created."
