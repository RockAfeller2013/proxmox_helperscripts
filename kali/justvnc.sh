#!/bin/bash
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/kali/xrdp.sh)"
# https://www.kali.org/docs/general-use/novnc-kali-in-browser/

set -e

sudo apt-get update && apt-get full-upgrade -y

echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
sysctl -p
systemctl stop ufw || true
systemctl disable ufw || true
apt-get --yes install qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent

sudo apt install -y novnc x11vnc
x11vnc -display :0 -autoport -localhost -nopw -bg -xkb -ncache -ncache_cr -quiet -forever
ss -antp | grep vnc
/usr/share/novnc/utils/novnc_proxy --listen 8081 --vnc localhost:5900
sudo systemctl enable ssh --now

echo "http://192.168.1.46:8081/vnc.html"

http://192.168.1.46:8081/vnc.html?host=192.168.1.46&port=5901&password=kali&autoconnect=true

