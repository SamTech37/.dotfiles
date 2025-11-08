#!/bin/bash

set -e

# ======= Configuration =======
APT_PACKAGES=(
    chewing-editor
    dconf-cli
    gnome-tweaks
    gnome-shell-extensions
    gnome-shell-extension-prefs
)

# ======= Script =======


echo "Installing packages..."
sudo apt install -y "${APT_PACKAGES[@]}"

# Read dconf settings for GNOME
if [ -f desktop/gnome/dconf-settings.ini ]; then
    echo "Loading GNOME settings..."
    dconf load /org/gnome/shell/ < desktop/gnome/dconf-settings.ini
else
    echo "[WARNING] GNOME settings file 'desktop/gnome/dconf-settings.ini' not found. Skipping GNOME settings import."
fi 

echo "Setup GUI complete!"
