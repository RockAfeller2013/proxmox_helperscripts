#!/bin/bash
# Fixed version — see comments for what changed and why.

sudo apt update

# Removed from this list: tldr, pinta, docker-compose-plugin, golang
# (none have a working apt candidate on this system — handled separately below).
sudo apt install -y \
  git \
  gh \
  curl \
  wget \
  jq \
  ca-certificates \
  build-essential \
  python3 \
  python3-pip \
  python3-venv \
  pipx \
  nodejs \
  npm \
  rustc \
  cargo \
  neovim \
  fzf \
  ripgrep \
  fd-find \
  bat \
  btop \
  htop \
  fastfetch \
  ffmpeg \
  gimp \
  libreoffice \
  vlc \
  flameshot \
  xournalpp \
  firefox \
  gum

# --------------------------------------------------------------------------
# Docker engine + compose plugin, no Docker Desktop.
# docker.io from Ubuntu's own repo doesn't ship docker-compose-plugin, which
# is why that package couldn't be located and docker.service never got
# created. Pulling both from Docker's official apt repo fixes it in one shot.
# --------------------------------------------------------------------------
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce

sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"   # log out/in (or `newgrp docker`) to use docker without sudo

# --- tldr: not in apt on this release, install via pipx instead ---
pipx install tldr || pip install --user tldr

# --- pinta: not in apt on this release, install via snap instead ---
sudo snap install pinta

# --------------------------------------------------------------------------
# Go: apt's "golang" metapackage name/PATH wiring is unreliable across
# releases (this is why `go` came back "command not found"). mise manages
# this cleanly and you're already installing mise below, so use it for Go.
# --------------------------------------------------------------------------
curl https://mise.jdx.dev/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate bash)"
mise use -g go@latest

# --------------------------------------------------------------------------
# Snaps: installing several back-to-back can hit
# 'snap "X" has "install-snap" change in progress' because snapd processes
# changes asynchronously. Retrying with a short backoff clears this reliably.
# --------------------------------------------------------------------------
install_snap() {
  local name="$1"; shift
  for i in 1 2 3; do
    if sudo snap install "$name" "$@"; then
      return 0
    fi
    echo "snap install $name failed (attempt $i), retrying in 5s..."
    sleep 5
  done
  echo "WARNING: failed to install snap '$name' after 3 attempts" >&2
}
install_snap code --classic
install_snap obsidian --classic
install_snap typora
install_snap localsend
install_snap brave

# --- uv ---
curl -LsSf https://astral.sh/uv/install.sh | sh

# --- pi ---
curl -fsSL https://pi.dev/install.sh | sh

# --- herdr ---
curl -fsSL https://herdr.dev/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

# --- treehouse / no-mistakes ---
curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh
curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh

# --------------------------------------------------------------------------
# npm global installs: the previous run failed because npm's default global
# prefix (/usr/local/lib/node_modules) isn't writable by a normal user.
# Point npm at a user-owned directory instead of using sudo with npm.
# --------------------------------------------------------------------------
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"

# gh-axi: confirmed correct install method per its own README is NOT
# `npm install -g gh-axi` — that's what produced "command not found" for it
# and its siblings. It installs as an agent "skill" instead:
npx -y skills add kunchenguid/gh-axi --skill gh-axi -g

# chrome-devtools-axi, lavish-axi, tasks-axi, quota-axi: I couldn't confirm
# these ship as plain global npm packages under these exact names (unlike
# gh-axi, which explicitly documents npx-based setup, not npm install -g).
# Check each project's own README for its supported install command before
# adding it back in — guessing the wrong install method is exactly what
# caused the original failures.

# --- lazygit / lazydocker (need Go — installed above via mise) ---
git clone https://github.com/jesseduffield/lazygit.git /tmp/lazygit
(cd /tmp/lazygit && go install)

git clone https://github.com/jesseduffield/lazydocker.git /tmp/lazydocker
(cd /tmp/lazydocker && go install)

# --------------------------------------------------------------------------
# zinit: the install script moved from doc/install.sh to scripts/install.sh
# a while back (that's the 404 at the end of your log). Fixed URL below.
# --------------------------------------------------------------------------
curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh | bash


# --------------------------------------------------------------------------
# Add HERDR to SSH Add this to the end of your ~/.bashrc (or ~/.zshrc if you use zsh):
# --------------------------------------------------------------------------
grep -qxF 'if [[ -n "$SSH_CONNECTION" && $- == *i* ]]; then exec HERDR; fi' ~/.bashrc || echo 'if [[ -n "$SSH_CONNECTION" && $- == *i* ]]; then exec HERDR; fi' >> ~/.bashrc

echo "Install complete"

