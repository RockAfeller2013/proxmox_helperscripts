#!/usr/bin/env bash
# MITRE CALDERA 5.x Automated Install for Kali Linux (corrected)
# Run as normal user with sudo privileges.

set -euo pipefail

USER_HOME="${HOME}"
USER_NAME="$(id -un)"
CALDERA_HOME="$USER_HOME/caldera5"
VENV_PATH="$USER_HOME/caldera_venv"
ATOMIC_TESTS_DIR="/opt/atomic-red-team"

echo "[+] Installing required packages"
sudo apt update
sudo apt install -y \
    python3-dev \
    python3-venv \
    python3-pip \
    git \
    curl \
    build-essential \
    golang-go \
    nodejs \
    npm \
    upx

echo "[+] Creating Python virtual environment"
python3 -m venv "$VENV_PATH"
. "$VENV_PATH/bin/activate"

echo "[+] Installing / updating CALDERA"
if [ -d "$CALDERA_HOME" ]; then
    cd "$CALDERA_HOME"
    git pull --recurse-submodules || true
else
    git clone --recursive https://github.com/mitre/caldera.git "$CALDERA_HOME"
    cd "$CALDERA_HOME"
fi

echo "[+] Installing official plugins"
mkdir -p plugins
plugins=(atomic stockpile sandcat training debrief manx response access compass)
for plugin in "${plugins[@]}"; do
    if [ ! -d "plugins/$plugin" ]; then
        git clone --recursive "https://github.com/mitre/${plugin}.git" "plugins/${plugin}" || true
    fi
done

echo "[+] Installing Atomic Red Team tests"
if [ ! -d "$ATOMIC_TESTS_DIR" ]; then
    sudo git clone https://github.com/redcanaryco/atomic-red-team.git "$ATOMIC_TESTS_DIR"
fi

echo "[+] Configuring Atomic plugin path"
mkdir -p "$CALDERA_HOME/plugins/atomic/conf"
cat > "$CALDERA_HOME/plugins/atomic/conf/local.yml" <<EOF
atomic_path: $ATOMIC_TESTS_DIR/atomics
EOF

echo "[+] Installing Python requirements"
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

echo "[+] Creating CALDERA local configuration"
mkdir -p conf
cat > conf/local.yml <<'YML'
app:
  host: 0.0.0.0
  port: 8888
  users:
    - username: admin
      password: changeme
      access: blue
    - username: red
      password: changeme
      access: red
plugins:
  - stockpile
  - sandcat
  - response
  - access
  - manx
  - compass
  - atomic
  - training
  - debrief
YML

echo "[+] Creating systemd service"
SERVICE_PATH="/etc/systemd/system/caldera.service"
sudo bash -c "cat > $SERVICE_PATH" <<EOF
[Unit]
Description=MITRE CALDERA Adversary Emulation Platform
After=network.target

[Service]
Type=simple
User=${USER_NAME}
WorkingDirectory=${CALDERA_HOME}
Environment=PATH=${VENV_PATH}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
ExecStart=${VENV_PATH}/bin/python3 ${CALDERA_HOME}/server.py --insecure
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "[+] Enabling and starting CALDERA service"
sudo systemctl daemon-reload
sudo systemctl enable caldera
sudo systemctl restart caldera

echo
echo "[+] CALDERA installed successfully"
echo "[+] Open: https://<your_ip>:8888"
echo "[+] Default login: admin / changeme"
echo
echo "[+] To view logs:"
echo "sudo journalctl -u caldera -f"
