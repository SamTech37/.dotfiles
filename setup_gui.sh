#!/bin/bash

set -e

# ======= Configuration =======
APT_PACKAGES=(
    chewing-editor
    fcitx5
    fcitx5-frontend-gtk4 fcitx5-frontend-gtk3 fcitx5-frontend-gtk2 fcitx5-frontend-qt5
    fcitx5-chewing
    dconf-cli
    dconf-editor
    gnome-tweaks
    gnome-shell-extensions
    gnome-shell-extension-prefs
    flatpak
)


GNOME_EXTENSIONS=(
    5090  # Space Bar
    973   # Switcher
    3843  # Just Perfection
    4839  # Clipboard History
    4548  # Tactile
    517   # Caffeine
)

# ======= Script =======

install_gnome_extension() {
    local ext_id="$1"
    local gnome_version
    gnome_version=$(gnome-shell --version | awk '{print $3}' | cut -d. -f1)

    echo "Installing GNOME extension ID: ${ext_id}..."
    local info
    info=$(curl -fsSL "https://extensions.gnome.org/extension-info/?pk=${ext_id}&shell_version=${gnome_version}")
    local download_url
    download_url=$(echo "$info" | python3 -c "import sys,json; print(json.load(sys.stdin)['download_url'])")

    curl -fsSL "https://extensions.gnome.org${download_url}" -o "/tmp/gnome-ext-${ext_id}.zip"
    gnome-extensions install --force "/tmp/gnome-ext-${ext_id}.zip"
    rm -f "/tmp/gnome-ext-${ext_id}.zip"
}


echo "Installing packages..."
sudo apt install -y "${APT_PACKAGES[@]}"


echo "Installing GNOME extensions..."
for ext_id in "${GNOME_EXTENSIONS[@]}"; do
    install_gnome_extension "$ext_id"
done

# get gnome-extension-manager via flatpak (GUI tool for browsing/updating extensions)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.mattjakeman.ExtensionManager


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

# Install custom .desktop files
echo "Installing custom .desktop files..."
mkdir -p "$HOME/.local/share/applications"
for f in desktop/applications/*.desktop; do
    sed "s|__HOME__|$HOME|g" "$f" > "$HOME/.local/share/applications/$(basename "$f")"
done

echo "Setup GUI complete!"
echo "[NOTE] Some changes (GNOME extensions, input method) will take effect after re-login or reboot."
