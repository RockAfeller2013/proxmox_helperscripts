# Auto installing Kali on Proxmox

- This scripts downloads the latest Kali QEMU image and deloys VM inside Proxmox, it then runs a Cloudint script to; Disable ipv6, Disable Firewall, Install Qemu Agent and configure RDP.

## References
- Setting up RDP with Xfce - https://www.kali.org/docs/general-use/xfce-with-rdp/
- Kali inside Proxmox (Guest VM) - https://www.kali.org/docs/virtualization/install-proxmox-guest-vm/
- wget https://cdimage.kali.org/current/kali-linux-2025.2-installer-amd64.iso -O /var/lib/vz/template/iso/kali-linux-2025.2-installer-amd64.iso
- All cloud config examples - https://cloudinit.readthedocs.io/en/latest/reference/examples.html
- Kali In The Browser (noVNC) - https://www.kali.org/docs/general-use/novnc-kali-in-browser/
- Cloud-init not working with Kali image - https://www.reddit.com/r/Proxmox/comments/1gnbcaz/cloudinit_not_working_with_kali_image/


  
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/kali/kali_install.sh)"
```

![hippo](https://media3.giphy.com/media/aUovxH8Vf9qDu/giphy.gif)
![til](https://raw.githubusercontent.com/hashrocket/hr-til/master/app/assets/images/banner.png)


# Test

![til](./app/assets/images/banner.png)

