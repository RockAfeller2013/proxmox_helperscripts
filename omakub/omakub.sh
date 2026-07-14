# sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/omakub/omakub.sh)"

#!/bin/bash
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/omakub/Omakub.sh)"

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

echo "========================================"
echo "         Omakub Installer"
echo "========================================"
echo

read -rp "Linux username: " USERNAME

if ! id "$USERNAME" >/dev/null 2>&1; then
    echo "Error: User '$USERNAME' does not exist."
    exit 1
fi

read -rsp "RDP password: " RDP_PASSWORD
echo
read -rsp "Confirm RDP password: " RDP_PASSWORD_CONFIRM
echo

if [[ "$RDP_PASSWORD" != "$RDP_PASSWORD_CONFIRM" ]]; then
    echo "Error: Passwords do not match."
    exit 1
fi

echo
echo "Updating packages..."
apt update

echo "Installing QEMU Guest Agent..."
apt install -y qemu-guest-agent
systemctl enable --now qemu-guest-agent

echo "Configuring GNOME Remote Desktop..."

USER_UID=$(id -u "$USERNAME")

sudo -u "$USERNAME" \
    XDG_RUNTIME_DIR="/run/user/$USER_UID" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_UID/bus" \
    bash <<EOF
gsettings set org.gnome.desktop.remote-desktop.rdp enable true
gsettings set org.gnome.desktop.remote-desktop.rdp view-only false
gsettings set org.gnome.desktop.remote-desktop.rdp auth-method "password"
gsettings set org.gnome.desktop.remote-desktop.rdp password "\$(echo -n "$RDP_PASSWORD" | base64)"
gsettings set org.gnome.desktop.remote-desktop.rdp network-access "any"

systemctl --user restart gnome-remote-desktop.service || true
EOF

echo "Disabling firewalls..."

systemctl stop ufw 2>/dev/null || true
systemctl disable ufw 2>/dev/null || true
ufw disable 2>/dev/null || true

systemctl stop firewalld 2>/dev/null || true
systemctl disable firewalld 2>/dev/null || true

echo "Disabling IPv6..."

cat >/etc/sysctl.d/10-disable-ipv6.conf <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

sysctl --system

echo "Installing Omakub..."

sudo -u "$USERNAME" bash -c 'wget -qO- https://omakub.org/install | bash'

echo
echo "========================================"
echo "Installation complete."
echo "========================================"
