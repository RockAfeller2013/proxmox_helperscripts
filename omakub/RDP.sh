#!/bin/bash
# enable-rdp-autologin.sh
# Enables single-login RDP access on Ubuntu by combining GDM autologin with
# GNOME Remote Desktop's user-session "Desktop Sharing" mode.
#
# Trade-off: the local desktop is unlocked with no password after boot, and
# RDP just shares that session (one credential prompt instead of two).
# Only use this on trusted/isolated machines (labs, internal VMs, etc.)
#
# Usage: sudo ./enable-rdp-autologin.sh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)."
    exit 1
fi

read -rp "Local username to autologin as: " LOGIN_USER
if ! id "$LOGIN_USER" >/dev/null 2>&1; then
    echo "User '$LOGIN_USER' does not exist."
    exit 1
fi

read -rp "RDP username [$LOGIN_USER]: " RDP_USER
RDP_USER=${RDP_USER:-$LOGIN_USER}

read -rsp "RDP password: " RDP_PASS
echo
if [[ -z "$RDP_PASS" ]]; then
    echo "Password cannot be empty."
    exit 1
fi

# ---- 1. Disable system-wide RDP service if it's running (avoid port conflict) ----
if systemctl is-active --quiet gnome-remote-desktop.service; then
    echo "==> Disabling system-wide gnome-remote-desktop.service..."
    systemctl disable --now gnome-remote-desktop.service
fi

# ---- 2. Configure GDM autologin ----
GDM_CONF="/etc/gdm3/custom.conf"
if [[ -f "$GDM_CONF" ]]; then
    echo "==> Configuring GDM autologin for $LOGIN_USER..."
    cp "$GDM_CONF" "${GDM_CONF}.bak.$(date +%s)"
    if grep -q "^\[daemon\]" "$GDM_CONF"; then
        sed -i '/^\[daemon\]/a AutomaticLoginEnable = true\nAutomaticLogin = '"$LOGIN_USER" "$GDM_CONF"
    else
        printf '\n[daemon]\nAutomaticLoginEnable = true\nAutomaticLogin = %s\n' "$LOGIN_USER" >> "$GDM_CONF"
    fi
else
    echo "WARNING: $GDM_CONF not found. Skipping autologin config — set it manually if using a different display manager."
fi

# ---- 3. Install gnome-remote-desktop ----
echo "==> Installing gnome-remote-desktop..."
apt update -qq
apt install -y gnome-remote-desktop >/dev/null

# ---- 4. Generate cert/key as the target user and enable user-session RDP ----
echo "==> Generating TLS certificate and enabling Desktop Sharing for $LOGIN_USER..."
USER_UID=$(id -u "$LOGIN_USER")

sudo -u "$LOGIN_USER" env XDG_RUNTIME_DIR="/run/user/$USER_UID" bash <<EOF
set -e
mkdir -p ~/.local/share/gnome-remote-desktop
cd ~/.local/share/gnome-remote-desktop
openssl req -x509 -newkey rsa:4096 -nodes \
    -keyout rdp-tls.key -out rdp-tls.pem \
    -days 3650 -subj "/CN=\$(hostname)" 2>/dev/null

grdctl rdp set-tls-cert ~/.local/share/gnome-remote-desktop/rdp-tls.pem
grdctl rdp set-tls-key ~/.local/share/gnome-remote-desktop/rdp-tls.key
grdctl rdp set-credentials "$RDP_USER" "$RDP_PASS"
grdctl rdp disable-view-only
grdctl rdp enable
EOF

# ---- 5. Firewall ----
echo "==> Opening firewall port 3389/tcp (if UFW is active)..."
if command -v ufw >/dev/null 2>&1; then
    ufw allow 3389/tcp || true
fi

echo
echo "========================================"
echo "RDP Autologin Configured"
echo "========================================"
echo "Local user '$LOGIN_USER' will autologin to the desktop on boot."
echo "RDP credentials: $RDP_USER / (as entered)"
IP=$(hostname -I | awk '{print $1}')
echo "Connect via RDP to: $IP:3389"
echo
echo "NOTE: A reboot is required for autologin and the user's remote-desktop"
echo "session to fully take effect."
echo "========================================"
