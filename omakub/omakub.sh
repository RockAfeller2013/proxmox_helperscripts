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

echo
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
systemctl start qemu-guest-agent

echo "Configuring GNOME Remote Desktop..."

USER_UID=$(id -u "$USERNAME")

sudo -u "$USERNAME" \
    XDG_RUNTIME_DIR="/run/user/$USER_UID" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_UID/bus" \
    bash <<EOF
gsettings set org.gnome.desktop.remote-desktop.rdp enable true
gsettings set org.gnome.desktop.remote-desktop.rdp view-only false
gsettings set org.gnome.desktop.remote-desktop.rdp screen-share-mode false
gsettings set org.gnome.desktop.remote-desktop.rdp negotiate-port true
gsettings set org.gnome.desktop.remote-desktop.rdp port 3389
EOF

echo "Configuring RDP credentials using grdctl..."

if command -v grdctl >/dev/null 2>&1; then
    sudo -u "$USERNAME" \
        XDG_RUNTIME_DIR="/run/user/$USER_UID" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_UID/bus" \
        bash <<EOF
grdctl rdp enable
grdctl rdp set-credentials "$USERNAME" "$RDP_PASSWORD"
EOF
else
    echo "Warning: grdctl not installed. Installing GNOME Remote Desktop..."
    apt install -y gnome-remote-desktop
fi

echo "Restarting GNOME Remote Desktop..."

sudo -u "$USERNAME" \
    XDG_RUNTIME_DIR="/run/user/$USER_UID" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_UID/bus" \
    systemctl --user restart gnome-remote-desktop.service || true

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
