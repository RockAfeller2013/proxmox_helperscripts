#!/bin/bash
set -e

# Enable SSH on Debian
sudo apt update
sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
sudo ufw allow ssh || true

echo "SSH is enabled and running."
