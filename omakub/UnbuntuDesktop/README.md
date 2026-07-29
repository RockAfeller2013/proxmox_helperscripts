# Unbuntu Desktop Template

## Create a image usng ISO 

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/omakub/ubuntu-desktop.sh)"
```

- create rockadmin user account
- untick require my password to login

# Remove CD and reboot

# Snapshot it

# It will autologin via Console

```bash
sudo ufw disable
sudo apt install qemu-guest-agent -y 
```

# From GUI / Terminal

- enable ssh
- eable rmote login

```bash
sudo apt update
sudo apt install ssh -y 
sudo apt install qemu-guest-agent -y 
```

## Login via SSH

## Disable IPv6

```bash
echo "Disabling IPv6..."

sudo tee /etc/sysctl.d/10-disable-ipv6.conf > /dev/null <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
```

```bash
sudo apt install curl -y 
sudo apt install net-tools -y 
sudo apt install qemu-guest-agent -y 
sudo apt install -y ansible
```

## Enable XRDP

```bash
sudo systemctl disable --now gnome-remote-desktop
sudo apt update && sudo apt install -y xfce4 xfce4-goodies xrdp && sudo adduser xrdp ssl-cert && echo "startxfce4" > ~/.xsession && sudo systemctl enable xrdp --now && sudo systemctl restart xrdp
```

```bash
cat > ~/.xsession <<'EOF'
#!/bin/sh
export DESKTOP_SESSION=xfce
export XDG_SESSION_DESKTOP=xfce
export XDG_CURRENT_DESKTOP=XFCE
startxfce4
EOF
```

### Disable Autologin to Console

```bash
sudo sed -i 's/^AutomaticLoginEnable=true/AutomaticLoginEnable=false/; s/^AutomaticLogin=rockadmin/#AutomaticLogin=rockadmin/' /etc/gdm3/custom.conf && sudo systemctl restart gdm3
```

```bash
chmod +x ~/.xsession

sudo sed -i 's/startwm_bash/startwm_bash/' /etc/xrdp/startwm.sh


sudo loginctl terminate-user $USER
sudo journalctl -u xrdp -n 50 --no-pager

sudo systemctl restart xrdp
sudo systemctl status xrdp
```

### Setup GRUB

```bash
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/; s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub && sudo update-grub
```

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


## Test RDP Login


# Tools 

```bash

bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/omakub/UnbuntuDesktop/install_dev_tools.sh)"

```

# Ubuntu VM Template Preparation / Cloud-Init Guides

## Ubuntu Cloud-Init Documentation
https://help.ubuntu.com/community/CloudInit

## Ubuntu Server - Introduction to Cloud-Init
https://documentation.ubuntu.com/server/explanation/intro-to-cloud-init/

## Cloud-Init CLI Reference (`cloud-init clean`)
https://docs.cloud-init.io/en/latest/reference/cli.html

## Cloud-Init Documentation Home
https://docs.cloud-init.io/

## Proxmox Cloud-Init Documentation
https://pve.proxmox.com/wiki/Cloud-Init_Support

## Proxmox Forum - Ubuntu Cloud-Init / Templates Discussion
https://forum.proxmox.com/threads/cloud-init-on-ubuntu-not-using-ubuntu-cloud-images.45107/
