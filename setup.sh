#!/bin/bash

set -e

# [TODO]
# installer part requires root privileges, while stow and config part doesn't
# perhaps split into two scripts with sudo only for the installer part
# [TODO]
# add a options Q&A section at the start to let user choose what to install/configure
# then proceed accordingly without anymore prompts
# [TODO]
# Compartmentalize

# ======= Configuration =======
APT_PACKAGES=(
    stow
    autojump
    ffmpeg
    git
    curl
    tmux
    flatpak
    vlc
    gcc
    build-essential
    wl-clipboard
    btop    
)

STOW_DIRS=(
    bash
    starship
    tmux
)

DEBUG_STOW="" # Set to "--simulate" to simulate stow actions instead of executing them

SAY_YES="-s -- -y"

# ======= Script =======

# some runtime
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh $SAY_YES # rust and cargo
source $HOME/.cargo/env


#node, conda, jvm and such, to be added



# independent installers

cargo install tlrc --locked # tlrc, rust client for tldr.pages 

curl -sS https://starship.rs/install.sh | sh $SAY_YES # starship prompt

    
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit -D -t /usr/local/bin/ # lazygit
    lazygit --version & rm lazygit lazygit.tar.gz


curl -fsSL https://fnm.vercel.app/install | bash

# Get your favorite tools via Distro's package manager
echo "Installing packages..."
sudo apt update
sudo apt install -y "${APT_PACKAGES[@]}"




# Backup existing dotfiles if they exist
echo "Backing up existing dotfiles..."
backup_dir=~/backup-dotfiles-$(date +%Y%m%d-%H%M%S)
mkdir -p "$backup_dir"

# Find all files in stow packages and backup conflicting ones
for package in "${STOW_DIRS[@]}"; do
    if [ -d "$package" ]; then
        find "$package" -type f | while read -r file; do
            # Remove package name prefix to get target path
            target_file=~/${file#*/}
            if [ -f "$target_file" ] && [ ! -L "$target_file" ]; then
                mkdir -p "$backup_dir/$(dirname "${file#*/}")"
                cp "$target_file" "$backup_dir/${file#*/}"
                rm "$target_file"
            fi
        done
    fi
done

# Check if .stowrc exists
if [ ! -f .stowrc ]; then
    echo "ERROR: .stowrc not found"
    exit 1
fi

# Stow packages
echo "Stowing dotfiles..."
for package in ${STOW_DIRS[@]}; do
    if [ -d "$package" ]; then
        echo "Stowing package: $package"
        stow "$DEBUG_STOW" --verbose --restow  "$package" #target is already set in .stowrc
    else
        echo "Warning: Package directory '$package' does not exist, skipping."
    fi
done

echo "Setup complete!"
