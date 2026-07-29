#!/bin/bash
set -e

sudo apt install cloud-init qemu-guest-agent

# Set template hostname
hostnamectl set-hostname ubuntu-template

# Remove old hostname references
sed -i '/127.0.1.1/d' /etc/hosts
echo "127.0.1.1 ubuntu-template" >> /etc/hosts

# Reset machine identity
cloud-init clean --machine-id || true


# Clean machine-specific identifiers
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id

# Clean SSH host keys (regenerated on first boot)
rm -f /etc/ssh/ssh_host_*

# Clean logs
journalctl --rotate
journalctl --vacuum-time=1s

# Clean temporary files
rm -rf /tmp/*
rm -rf /var/tmp/*

# Clean apt cache
apt clean

# Remove shell history
history -c
unset HISTFILE

rm -f /root/.bash_history
rm -f ~/.bash_history

echo "VM ready for templating. Shutdown now."
shutdown -h now
poweroff
