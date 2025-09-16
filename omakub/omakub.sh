# bash -c "$(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/omakub/Omakub.sh)"


sudo apt update

# VirtIO NIC and disk drivers are already included in modern Ubuntu kernels. You don’t need to install extra drivers manually.

sudo apt install -y qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent

wget -qO- https://omakub.org/install | bash
