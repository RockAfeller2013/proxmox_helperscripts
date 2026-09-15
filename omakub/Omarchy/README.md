```bash


apt update && apt install -y xorriso
curl -fsSL 'https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/omakub/Omarchy/create-omarchy-vm.sh' | bash

```

- Guide: Enabling WayVNC Autostart - https://github.com/omacom/omarchy/discussions/1284
- Connect to an Omarchy Fleet desktop with noVNC - https://cua.ai/docs/how-to-guides/sandbox/connect-to-omarchy-with-novnc
- Omarchy https://marketplace.digitalocean.com/apps/omarchy
- RDP - omacom/omarchy#3350
- Unattended Installs - https://omarchy.org/manual/unattended-installs/


```
Just tell it to skip SSH setup with ENABLE_SSH=false. In a pipeline, prefix the env var on the command that should see it — that's bash, not curl:

bash
curl -fsSL 'https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/refs/heads/main/omakub/Omarchy/create-omarchy-vm.sh' | ENABLE_SSH=false bash

(ENABLE_SSH=false curl ... | bash wouldn't work — that only sets the var for curl, not for the bash process reading the piped script.)

With ENABLE_SSH=false, the script skips the whole authorized_keys block entirely — no prompt, no error, no key required.

One thing worth knowing: Omarchy ships with sshd disabled and the firewall port closed by default, and the unattended-install flow only opens SSH access when it finds an authorized_keys file. So without one, you won't be able to SSH into this VM at all — you'll only have the Proxmox console (noVNC/serial) to log in. For a throwaway dev box that's often fine; just flagging it so it's not a surprise later. If you want SSH back at some point, you can always drop a key in and re-enable sshd from inside the VM afterward, or re-run with a key next time.
```


Run this on the Proxmox host, as root — that matches the default SSH_PUBLIC_KEY_FILE="${SSH_PUBLIC_KEY_FILE:-$HOME/.ssh/id_ed25519.pub}", which resolved to /root/.ssh/id_ed25519.pub in your earlier error:

bash
mkdir -p /root/.ssh
chmod 700 /root/.ssh
ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N "" -C "omarchy-vm"
-N "" sets an empty passphrase so it's non-interactive (drop it if you want a passphrase — it'll prompt you instead)
ssh-keygen won't silently overwrite an existing key at that path; it'll ask first

Verify it's there:

bash
cat /root/.ssh/id_ed25519.pub

With that in place, just run the script normally (leave ENABLE_SSH unset or true) — it'll find the key at the default path, skip the prompt entirely, and install it as the VM user's authorized_keys, opening sshd and the firewall for it on first boot.
