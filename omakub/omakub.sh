# bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/omakub/Omakub.sh)"
#!/bin/bash
set -e

USERNAME="your_username"
RDP_PASSWORD="password"

apt update
apt install -y qemu-guest-agent
systemctl enable --now qemu-guest-agent

# Enable GNOME Remote Desktop (RDP) for the target user
sudo -u "$USERNAME" XDG_RUNTIME_DIR="/run/user/$(id -u "$USERNAME")" bash <<EOSU
export DBUS_SESSION_BUS_ADDRESS="unix:path=\${XDG_RUNTIME_DIR}/bus"

gsettings set org.gnome.desktop.remote-desktop.rdp enable true
gsettings set org.gnome.desktop.remote-desktop.rdp view-only false
gsettings set org.gnome.desktop.remote-desktop.rdp auth-method "password"
gsettings set org.gnome.desktop.remote-desktop.rdp password "\$(echo -n '${RDP_PASSWORD}' | base64)"
gsettings set org.gnome.desktop.remote-desktop.rdp network-access "any"

systemctl --user restart gnome-remote-desktop.service
EOSU

# Disable firewalls
systemctl stop ufw 2>/dev/null || true
systemctl disable ufw 2>/dev/null || true
ufw disable 2>/dev/null || true

systemctl stop firewalld 2>/dev/null || true
systemctl disable firewalld 2>/dev/null || true

# Disable IPv6
tee /etc/sysctl.d/10-disable-ipv6.conf > /dev/null <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
sysctl --system

# Install Omakub
sudo -u "$USERNAME" bash -c 'wget -qO- https://omakub.org/install | bash'
