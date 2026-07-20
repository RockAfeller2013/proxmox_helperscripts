#!/usr/bin/env bash
set -e
SCRIPT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/vm/ubuntu2504-vm.sh"
SCRIPT="/tmp/ubuntu2604-desktop-vm-base.sh"
echo "Downloading Proxmox Ubuntu VM builder..."
curl -fsSL "$SCRIPT_URL" -o "$SCRIPT"
echo "Updating Ubuntu version..."
sed -i \
    's/ubuntu2504-vm/ubuntu2604-desktop-vm/g;
     s/ubuntu2504/ubuntu2604/g;
     s/Ubuntu 25.04/Ubuntu 26.04/g;
     s/plucky/resolute/g;
     s/ubuntu-25.04-server-cloudimg-amd64.img/ubuntu-26.04-server-cloudimg-amd64.img/g' \
    "$SCRIPT"
echo "Injecting Cloud-Init desktop configuration..."
PATCH=$(mktemp)
cat > "$PATCH" <<'PATCHEOF'
msg_info "Creating Ubuntu Desktop Cloud-Init configuration"
mkdir -p /var/lib/vz/snippets
cat > /var/lib/vz/snippets/ubuntu2604-desktop-user-data.yaml <<'CLOUD'
#cloud-config
package_update: true
package_upgrade: true
packages:
  - ubuntu-desktop
  - xrdp
  - openssh-server
  - curl
  - net-tools
  - qemu-guest-agent
  - ansible
  - git
  - vim
  - wget
  - unzip
runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  - systemctl enable xrdp
  - adduser xrdp ssl-cert || true
  - ufw disable
  - |
      cat >/etc/sysctl.d/10-disable-ipv6.conf <<-SYSCTLEOF
      net.ipv6.conf.all.disable_ipv6 = 1
      net.ipv6.conf.default.disable_ipv6 = 1
      net.ipv6.conf.lo.disable_ipv6 = 1
      SYSCTLEOF
  - sysctl --system
  - |
      cat >/etc/xrdp/startwm.sh <<-STARTWMEOF
      #!/bin/sh
      export GNOME_SHELL_SESSION_MODE=ubuntu
      export XDG_CURRENT_DESKTOP=ubuntu:GNOME
      exec gnome-session
      STARTWMEOF
  - chmod +x /etc/xrdp/startwm.sh
  - systemctl restart xrdp
final_message: "Ubuntu 26.04 GNOME Desktop ready"
CLOUD
qm set $VMID --cicustom "user=local:snippets/ubuntu2604-desktop-user-data.yaml"
msg_ok "Cloud-Init desktop configuration applied"
PATCHEOF
python3 - "$SCRIPT" "$PATCH" <<'PY'
from pathlib import Path
import sys
script = Path(sys.argv[1])
patch = Path(sys.argv[2])
data = script.read_text()
insert = patch.read_text()
marker = "DESCRIPTION=$("
if marker not in data:
    print("ERROR: injection marker not found in upstream script; aborting.", file=sys.stderr)
    sys.exit(1)
data = data.replace(marker, insert + "\n" + marker)
script.write_text(data)
PY
chmod +x "$SCRIPT"
echo
echo "Created:"
echo "$SCRIPT"
echo
echo "Run:"
echo "bash $SCRIPT"
