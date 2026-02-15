# Install Caldera on Kali Linux



```
sudo update --fix-missing -y
sudo apt install caldera
caldera --insecure --build
https://localhost:8888
red / admin


```

```
cd /usr/share/caldera/plugins
sudo git clone https://github.com/mitre/stockpile.git
sudo git clone https://github.com/mitre/atomic.git
sudo git clone https://github.com/mitre/sandcat.git
sudo git clone https://github.com/mitre/gameboard.git
sudo git clone https://github.com/mitre/training.git

```

```

#!/usr/bin/env bash

set -e

CALDERA_DIR="/opt/caldera"
ATOMIC_DIR="/opt/atomic-red-team"

echo "[+] Installing dependencies"
sudo apt update
sudo apt install -y git python3 python3-pip golang powershell

echo "[+] Installing Caldera"
if [ ! -d "$CALDERA_DIR" ]; then
    sudo git clone https://github.com/mitre/caldera.git "$CALDERA_DIR"
fi

echo "[+] Installing Caldera plugins"
sudo mkdir -p "$CALDERA_DIR/plugins"
cd "$CALDERA_DIR/plugins"

for repo in stockpile atomic sandcat training gameboard; do
    if [ ! -d "$repo" ]; then
        sudo git clone "https://github.com/mitre/$repo.git"
    fi
done

echo "[+] Installing Atomic Red Team tests"
if [ ! -d "$ATOMIC_DIR" ]; then
    sudo git clone https://github.com/redcanaryco/atomic-red-team.git "$ATOMIC_DIR"
fi

echo "[+] Configuring Atomic plugin path"
CONF_FILE="$CALDERA_DIR/plugins/atomic/conf.yml"

if [ -f "$CONF_FILE" ]; then
    sudo sed -i "s|^atomic_path:.*|atomic_path: $ATOMIC_DIR/atomics|" "$CONF_FILE" || true
else
    echo "atomic_path: $ATOMIC_DIR/atomics" | sudo tee "$CONF_FILE" >/dev/null
fi

echo "[+] Installing Python requirements"
cd "$CALDERA_DIR"
sudo pip3 install -r requirements.txt

echo
echo "[+] Installation complete"
echo "[+] Start Caldera with:"
echo "cd $CALDERA_DIR && python3 server.py --insecure --build"
echo
echo "[+] Then open: https://localhost:8888"
echo "    login: red / admin"

```

```
After sudo apt install caldera
1) Start MITRE CALDERA
caldera --insecure --build


Open:

https://localhost:8888


Default login:

red / admin

2) Install ALL official plugins

Stop Caldera, then run:

cd /usr/share/caldera/plugins
sudo git clone https://github.com/mitre/stockpile.git
sudo git clone https://github.com/mitre/atomic.git
sudo git clone https://github.com/mitre/sandcat.git
sudo git clone https://github.com/mitre/gameboard.git
sudo git clone https://github.com/mitre/training.git


Restart:

caldera --insecure --build

3) Install Atomic Red Team tests (actual test library)

Install dependencies:

sudo apt install powershell -y


Download tests:

sudo mkdir -p /opt/atomic-red-team
cd /opt
sudo git clone https://github.com/redcanaryco/atomic-red-team.git


Tell Caldera Atomic plugin where tests live:

Edit:

sudo nano /usr/share/caldera/plugins/atomic/conf.yml


Set:

atomic_path: /opt/atomic-red-team/atomics


Restart Caldera again:

caldera --insecure --build

4) Create an agent (Sandcat)

In Caldera UI:

Agents → Deploy Agent → Sandcat

Linux one-liner example:

curl -sk https://localhost:8888/file/download -H "file:sandcat.go" -o sandcat.go
go build sandcat.go
./sandcat -server https://YOUR_CALDERA_IP:8888 -group red


OR faster precompiled binary:

curl -sk https://YOUR_CALDERA_IP:8888/file/download -H "file:sandcat" -o sandcat
chmod +x sandcat
./sandcat -server https://YOUR_CALDERA_IP:8888 -group red

```
