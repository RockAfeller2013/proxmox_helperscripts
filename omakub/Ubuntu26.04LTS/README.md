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
bash -c "$(curl -fsSL https://raw.githubusercontent.com/<repo>/ubuntu2604-desktop-vm.sh)"
