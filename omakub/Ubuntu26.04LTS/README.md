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
## 

How to fix, in the Proxmox web UI:

Select the VM → Cloud-Init tab.
Set User, Password (or SSH public key), and confirm networking (DHCP is fine for most setups).
Click Regenerate Image.
Then start the VM.

## Setup SSH

## Install Omakub

```bash
wget -qO- https://omakub.org/install | bash
```
