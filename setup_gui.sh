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
    flatpak
)


GNOME_EXTENSIONS=(
    https://extensions.gnome.org/extension/5090/space-bar/
    https://extensions.gnome.org/extension/973/switcher/
    https://extensions.gnome.org/extension/3843/just-perfection/
    https://extensions.gnome.org/extension/4839/clipboard-history/
    https://extensions.gnome.org/extension/4548/tactile/
)

# ======= Script =======


echo "Installing packages..."
sudo apt install -y "${APT_PACKAGES[@]}"


# get gnome-extension-manager via flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.mattjakeman.ExtensionManager
# [TODO] find a way to install extensions via command line instead of manual


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
