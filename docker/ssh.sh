#!/bin/bash
set -e

# Enable SSH on Debian
sudo apt update
sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
sudo ufw allow ssh || true

echo "SSH is enabled and running."

# Enable root SSH login on Debian
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH service
sudo systemctl restart ssh

echo "Root SSH login enabled. Use: ssh root@<server-ip>"


# Create admin user with sudo access for SSH login
NEWUSER="admin"
PASSWORD="password"   # change this

# Create user and set password
sudo useradd -m -s /bin/bash "$NEWUSER"
echo "$NEWUSER:$PASSWORD" | sudo chpasswd

# Add to sudo group
sudo usermod -aG sudo "$NEWUSER"

# Ensure SSH allows password login
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

echo "User '$NEWUSER' created with sudo privileges. You can SSH using: ssh $NEWUSER@<server-ip>"
