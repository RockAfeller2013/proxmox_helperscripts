#!/bin/bash

sudo apt update

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
golang \
rustc \
cargo \
docker.io \
docker-compose-plugin \
neovim \
fzf \
ripgrep \
fd-find \
bat \
tldr \
btop \
htop \
fastfetch \
ffmpeg \
gimp \
libreoffice \
vlc \
flameshot \
xournalpp \
pinta \
firefox \
gum

sudo systemctl enable --now docker

sudo snap install code --classic
sudo snap install obsidian --classic
sudo snap install typora
sudo snap install localsend
sudo snap install brave

curl -fsSL https://mise.jdx.dev/install.sh | sh

curl -LsSf https://astral.sh/uv/install.sh | sh

curl -fsSL https://pi.dev/install.sh | sh

curl -fsSL https://herdr.dev/install.sh | sh

curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh

curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh

npm install -g \
gh-axi \
chrome-devtools-axi \
lavish-axi \
tasks-axi \
quota-axi

gh-axi setup hooks
chrome-devtools-axi setup hooks
lavish-axi setup hooks

git clone https://github.com/jesseduffield/lazygit.git /tmp/lazygit
cd /tmp/lazygit
go install

cd ~

git clone https://github.com/jesseduffield/lazydocker.git /tmp/lazydocker
cd /tmp/lazydocker
go install

cd ~

curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/master/doc/install.sh | bash

echo "Install complete"
