#!/usr/bin/env bash
# Clone CALDERA official plugins using a GitHub token

set -euo pipefail

CALDERA_DIR="$HOME/caldera5/plugins"
GITHUB_TOKEN="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"

mkdir -p "$CALDERA_DIR"
cd "$CALDERA_DIR"

plugins=(atomic stockpile sandcat training debrief manx response access compass)

for plugin in "${plugins[@]}"; do
    if [ ! -d "$plugin" ]; then
        echo "[+] Cloning $plugin"
        git clone --recursive "https://$GITHUB_TOKEN@github.com/mitre/$plugin.git" "$plugin"
    else
        echo "[+] $plugin already exists. Skipping."
    fi
done

echo "[+] All official CALDERA plugins cloned."
