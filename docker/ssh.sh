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

