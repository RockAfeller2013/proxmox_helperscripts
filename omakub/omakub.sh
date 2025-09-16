# bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/omakub/Omakub.sh)"
sudo su

sudo apt update

# VirtIO NIC and disk drivers are already included in modern Ubuntu kernels. You don’t need to install extra drivers manually.

sudo apt install -y qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent

gsettings set org.gnome.desktop.remote-desktop.rdp enable true
gsettings set org.gnome.desktop.remote-desktop.rdp view-only false
gsettings set org.gnome.desktop.remote-desktop.rdp auth-method "password"
gsettings set org.gnome.desktop.remote-desktop.rdp password "$(echo -n 'password' | base64)"


# Enable RDP
gsettings set org.gnome.desktop.remote-desktop.rdp enable true
gsettings set org.gnome.desktop.remote-desktop.rdp allow-clipping true

# Optional: enable sharing of current session
gsettings set org.gnome.desktop.remote-desktop.rdp network-access "any"
systemctl --user restart gnome-remote-desktop

# Allow RDP access
#gsettings set org.gnome.desktop.remote-desktop.rdp enable true

# Set RDP authentication (replace with your password)
#secret=$(echo -n "password" | base64)
#gsettings set org.gnome.desktop.remote-desktop.rdp password "$secret"

# Allow screen sharing promptless
#gsettings set org.gnome.desktop.remote-desktop.rdp view-only false

# Enable required services
#systemctl --user enable --now gnome-remote-desktop.service

sudo systemctl stop ufw
sudo systemctl disable ufw
sudo ufw disable

sudo systemctl stop firewalld
sudo systemctl disable firewalld

sudo tee /etc/sysctl.d/10-disable-ipv6.conf > /dev/null <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

sudo sysctl --system


wget -qO- https://omakub.org/install | bash
