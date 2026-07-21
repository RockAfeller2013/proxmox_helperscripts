#!/usr/bin/env bash

set -euo pipefail

echo "Updating system..."
sudo apt update
sudo apt upgrade -y

echo "Installing base packages..."

sudo apt install -y \
    bash \
    git \
    curl \
    wget \
    unzip \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    ruby-full \
    golang \
    default-jdk \
    docker.io \
    docker-compose-plugin \
    ripgrep \
    fd-find \
    bat \
    fzf \
    btop \
    htop \
    neovim \
    libreoffice \
    software-properties-common


echo "Installing eza..."

sudo apt install -y eza || {
    curl -fsSL https://deb.gierens.de/apt/key.gpg | \
        sudo gpg --dearmor -o /usr/share/keyrings/deb.gierens.gpg

    echo "deb [signed-by=/usr/share/keyrings/deb.gierens.gpg] \
    https://deb.gierens.de/ stable main" | \
    sudo tee /etc/apt/sources.list.d/eza.list

    sudo apt update
    sudo apt install -y eza
}


echo "Installing Alacritty..."

sudo apt install -y alacritty


echo "Installing Starship..."

curl -sS https://starship.rs/install.sh | sh -s -- -y


echo "Installing zoxide..."

curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash


echo "Installing tldr..."

sudo apt install -y tldr


echo "Installing Zellij..."

cargo install --locked zellij || true


echo "Installing LazyGit..."

LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
| grep tag_name \
| cut -d '"' -f 4)

curl -Lo lazygit.tar.gz \
"https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz"

tar xf lazygit.tar.gz lazygit

sudo install lazygit /usr/local/bin/

rm lazygit.tar.gz lazygit


echo "Installing LazyDocker..."

LAZYDOCKER_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest \
| grep tag_name \
| cut -d '"' -f 4)

curl -Lo lazydocker.tar.gz \
"https://github.com/jesseduffield/lazydocker/releases/download/${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION#v}_Linux_x86_64.tar.gz"

tar xf lazydocker.tar.gz lazydocker

sudo install lazydocker /usr/local/bin/

rm lazydocker.tar.gz lazydocker


echo "Installing GitHub CLI..."

curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null

sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" | \
sudo tee /etc/apt/sources.list.d/github-cli.list

sudo apt update
sudo apt install -y gh


echo "Installing mise..."

curl https://mise.run | sh


echo "Installing VS Code..."

wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/packages.microsoft.gpg >/dev/null

echo "deb [arch=amd64,arm64,armhf \
signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" | \
sudo tee /etc/apt/sources.list.d/vscode.list

sudo apt update
sudo apt install -y code


echo "Installing LazyVim..."

rm -rf ~/.config/nvim

git clone https://github.com/LazyVim/starter ~/.config/nvim

rm -rf ~/.config/nvim/.git


echo "Installing Fastfetch..."

sudo apt install -y fastfetch


echo "Installing Google Chrome..."

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

sudo apt install -y ./google-chrome-stable_current_amd64.deb

rm google-chrome-stable_current_amd64.deb


echo "Installing Obsidian..."

wget -O obsidian.deb \
https://github.com/obsidianmd/obsidian-releases/releases/latest/download/obsidian_amd64.deb

sudo apt install -y ./obsidian.deb

rm obsidian.deb


echo "Installing Typora..."

wget -qO- https://typora.io/linux/public-key.asc | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/typora.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/typora.gpg] \
https://typora.io/linux ./ " | \
sudo tee /etc/apt/sources.list.d/typora.list

sudo apt update
sudo apt install -y typora


echo "Installing Spotify..."

curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | \
sudo gpg --dearmor -o /usr/share/keyrings/spotify.gpg

echo "deb [signed-by=/usr/share/keyrings/spotify.gpg] \
http://repository.spotify.com stable non-free" | \
sudo tee /etc/apt/sources.list.d/spotify.list

sudo apt update
sudo apt install -y spotify-client


echo "Installing Signal..."

wget -O- https://updates.signal.org/desktop/apt/keys.asc | \
sudo gpg --dearmor -o /usr/share/keyrings/signal.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal.gpg] \
https://updates.signal.org/desktop/apt xenial main" | \
sudo tee /etc/apt/sources.list.d/signal.list

sudo apt update
sudo apt install -y signal-desktop


echo "Installing LocalSend..."

wget -O localsend.deb \
https://github.com/localsend/localsend/releases/latest/download/localsend-linux-x86-64.deb

sudo apt install -y ./localsend.deb

rm localsend.deb


echo "Installing 1Password..."

curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] \
https://downloads.1password.com/linux/debian/amd64 stable main" | \
sudo tee /etc/apt/sources.list.d/1password.list

sudo apt update
sudo apt install -y 1password


echo "Configuring shell..."

cat <<'EOF' >> ~/.bashrc

eval "$(starship init bash)"
eval "$(zoxide init bash)"

alias cat="batcat"
alias ls="eza"
alias ll="eza -lah"

EOF


echo "Adding user to docker group..."

sudo usermod -aG docker "$USER"


echo "Installing Rust for Zellij support..."

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
sh -s -- -y

echo "Installing UV"

curl -LsSf https://astral.sh/uv/install.sh | sh

echo ""
echo "Installation complete."
echo "Logout/login required for Docker permissions."
echo "Restart terminal for shell changes."
