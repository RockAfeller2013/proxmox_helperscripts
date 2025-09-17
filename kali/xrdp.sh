#!/bin/bash
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/kali/xrdp.sh)"

set -e

#apt-get update
#apt-get full-upgrade -y

echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
sysctl -p
systemctl stop ufw || true
systemctl disable ufw || true
apt-get --yes install qemu-guest-agent kali-desktop-xfce xorg xrdp xorgxrdp
sudo systemctl enable --now qemu-guest-agent
sed -i 's/port=3389/port=3390/g' /etc/xrdp/xrdp.ini
bash -c "$(curl -fsSL https://gitlab.com/kalilinux/recipes/kali-scripts/-/raw/main/xfce4.sh)"
sudo systemctl enable xrdp --now
sudo systemctl enable xrdp-sesman --now
sudo systemctl restart xrdp
sudo systemctl restart xrdp-sesman
echo 'kali:kali' | chpasswd
bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/kali/rdpconfig.sh)"
