#!/bin/bash

set -e

# ======= Configuration =======
APT_PACKAGES=(
    stow
    autojump
    ffmpeg
)

STOW_DIRS=(
    bash
    starship
    tmux
)

DEBUG_STOW="" # Set to "--simulate" to simulate stow actions instead of executing them

# ======= Script =======


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
