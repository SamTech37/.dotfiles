#!/bin/bash

set -e

# ======= Configuration =======
APT_PACKAGES=(
    chewing-editor
    dconf-cli
    dconf-editor
    gnome-tweaks
    gnome-shell-extensions
    gnome-shell-extension-prefs
)

# ======= Script =======


echo "Installing packages..."
sudo apt install -y "${APT_PACKAGES[@]}"

# Read dconf settings for GNOME Shell
if [ -f desktop/gnome/dconf-shell.ini ]; then
    echo "Loading GNOME Shell settings..."
    dconf load /org/gnome/shell/ < desktop/gnome/dconf-shell.ini
else
    echo "[WARNING] 'desktop/gnome/dconf-shell.ini' not found. Skipping Shell settings."
fi 

# Read dconf settings for GNOME Desktop
if [ -f desktop/gnome/dconf-desktop.ini ]; then
    echo "Loading GNOME Desktop settings..."
    dconf load /org/gnome/desktop/ < desktop/gnome/dconf-desktop.ini
else
    echo "[WARNING] 'desktop/gnome/dconf-desktop.ini' not found. Skipping Desktop settings."
fi

echo "Setup GUI complete!"
