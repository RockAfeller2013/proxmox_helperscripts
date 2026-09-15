VMID=120 \
VM_NAME=omarchy-ai \
STORAGE=local-lvm \
ISO_STORAGE=local \
DISK_SIZE=120G \
MEMORY=32768 \
CORES=12 \
BRIDGE=vmbr0 \
USERNAME=rock \
FULL_NAME="Rock Ade" \
GIT_EMAIL="rock@example.com" \
TIMEZONE=Australia/Brisbane \
ENABLE_SSH=true \
SSH_PUBLIC_KEY_FILE=/root/.ssh/id_ed25519.pub \
ENABLE_TAILSCALE=false \
bash -c "$(curl -fsSL 'https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/omakub/Omarchy/create-omarchy-vm.sh')"
