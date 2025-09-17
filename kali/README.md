# kali auto install on Proxmox

- This scripts downloads the latest Kali QEMU image and deloys VM inside Proxmox, it then runs a Cloudint script to; Disable ipv6, Disable Firewall, Install Qemu Agent and configure RDP.

## References
- Setting up RDP with Xfce - https://www.kali.org/docs/general-use/xfce-with-rdp/
- Kali inside Proxmox (Guest VM) - https://www.kali.org/docs/virtualization/install-proxmox-guest-vm/
- wget https://cdimage.kali.org/current/kali-linux-2025.2-installer-amd64.iso -O /var/lib/vz/template/iso/kali-linux-2025.2-installer-amd64.iso
  
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/kali/kali_install.sh)"
```
