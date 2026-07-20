# Ubuntu 26.04 Desktop VM for Proxmox

## Description

Creates an Ubuntu 26.04 LTS Desktop VM using the Proxmox Community Script framework.

Features:

- Ubuntu 26.04 LTS Cloud Image
- Cloud-Init enabled
- Full GNOME Desktop
- xRDP remote desktop
- QEMU Guest Agent
- SSH
- Ansible
- Git
- Vim
- Curl
- Net-tools
- Wget
- Unzip
- UFW disabled
- IPv6 disabled

## Usage

Run on the Proxmox host:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/omakub/Ubuntu26.04LTS/ubuntu2604-desktop-vm.sh)"
```

# Cloud-Init & SSH Setup

# 1. Create VM
qm create $VMID ...

# 2. Import Ubuntu cloud image
qm importdisk $VMID ubuntu-26.04-server-cloudimg-amd64.img $STORAGE

# 3. Attach OS disk + Cloud-Init disk
qm set $VMID \
  -scsi0 ${DISK1_REF} \
  -ide2 ${STORAGE}:cloudinit

# 4. Create user-data.yaml automatically
/var/lib/vz/snippets/ubuntu2604-desktop-user-data.yaml

# 5. Attach custom Cloud-Init configuration automatically
qm set $VMID \
  --cicustom "user=<snippet-storage>:snippets/ubuntu2604-desktop-user-data.yaml"

# 6. Start VM
qm start $VMID

## How to fix, in the Proxmox web UI

1. Select the VM → **Cloud-Init** tab.
2. Set **User**, **Password** (or SSH public key), and confirm networking (DHCP is fine for most setups).
3. Click **Regenerate Image**.
4. Then start the VM.

## Setup SSH

Enable passwordless SSH to Proxmox.

Generate a key:

```
ssh-keygen -t ed25519
```

Copy it to the Proxmox host:

```
ssh-copy-id root@<proxmox-ip>
```

Test it:

```
ssh root@<proxmox-ip>
```

## Install Omakub

```bash
wget -qO- https://omakub.org/install | bash
```
