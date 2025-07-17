#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(realpath "$SCRIPT_DIR/..")"  # assumes scripts are in repo_root/scripts/
USER_HOME="/home/$SUDO_USER"

source "$SCRIPT_DIR/helper.sh"

check_root
check_os

# Get the directory of the current script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source helper file
source $SCRIPT_DIR/helper.sh

log_message "Installation started for theming section"
print_info "\nStarting theming setup..."

# Install theming tools
run_command "pacman -S --noconfirm nwg-look" "Install nwg-look for GTK theme management" "yes"
run_command "pacman -S --noconfirm qt5ct qt6ct kvantum" "Install Qt5, Qt6 Settings, and Kvantum theme engines" "yes"

# === MONOCHROME GTK + ICON THEME INSTALLATION ===

# Install Papirus Light Mono (monochrome icons)
run_command "yay -S --sudoloop --noconfirm papirus-icon-theme-git" "Install Papirus icon theme (includes Light Mono)" "yes" "no"

# Install FlatColor GTK + Kvantum theme (monochrome-friendly)
run_command "git clone https://github.com/pwyde/monochrome-kde.git /tmp/monochrome-kde" "Clone Monochrome KDE theme repo" "yes"
run_command "cp -r /tmp/monochrome-kde/themes/* /usr/share/themes/" "Install GTK themes" "no"
run_command "cp -r /tmp/monochrome-kde/icons/* /usr/share/icons/" "Install icon themes" "no"

# Apply GTK theme
GTK_CONFIG_DIR="/home/$SUDO_USER/.config/gtk-3.0"
mkdir -p "$GTK_CONFIG_DIR"
echo -e "[Settings]\ngtk-theme-name=FlatColor\ngtk-icon-theme-name=Papirus-Light-Mono\ngtk-font-name=JetBrainsMono 10" > "$GTK_CONFIG_DIR/settings.ini"

# Apply Kvantum theme
KVANTUM_DIR="/home/$SUDO_USER/.config/Kvantum"
mkdir -p "$KVANTUM_DIR"
echo "FlatColor" > "$KVANTUM_DIR/kvantum.kvconfig"

# Copy Kitty config with monochrome config (you should provide it at this path)
run_command "cp -r /home/$SUDO_USER/hyprbw/configs/kitty /home/$SUDO_USER/.config/" "Copy monochrome Kitty config" "yes" "no"

# === COPY USER ASSETS (BGs, Lockscreens, etc.) ===

USER_ASSETS_DIR="/home/$SUDO_USER/.config/assets"
mkdir -p "$USER_ASSETS_DIR"

ASSETS_SRC="/home/$SUDO_USER/hyprbw/assets"
if [ -d "$ASSETS_SRC" ]; then
    run_command "cp -r $ASSETS_SRC/* $USER_ASSETS_DIR/" "Copy user theming assets" "no"
else
    print_warning "Assets folder not found at $ASSETS_SRC. Skipping asset copy."
    log_message "Assets folder missing, skipped copying assets."
fi

# === SDDM MONOCHROME THEME ===

SDDM_THEME_NAME="monochrome"
SDDM_THEME_SRC="/tmp/monochrome-kde/sddm/themes/$SDDM_THEME_NAME"
SDDM_THEME_DEST="/usr/share/sddm/themes/$SDDM_THEME_NAME"

if [ -d "$SDDM_THEME_SRC" ]; then
    print_info "\nSetting up SDDM theme: $SDDM_THEME_NAME"

    run_command "cp -r $SDDM_THEME_SRC $SDDM_THEME_DEST" "Copy SDDM theme folder" "no"
    run_command "chown -R root:root $SDDM_THEME_DEST" "Fix SDDM theme ownership" "no"
    run_command "chmod -R 755 $SDDM_THEME_DEST" "Fix SDDM theme permissions" "no"

    run_command "mkdir -p /etc/sddm.conf.d" "Ensure SDDM config dir exists" "no"
    echo -e "[Theme]\nCurrent=$SDDM_THEME_NAME" | sudo tee /etc/sddm.conf.d/00-$SDDM_THEME_NAME.conf > /dev/null
    log_message "SDDM theme config written to /etc/sddm.conf.d/00-$SDDM_THEME_NAME.conf"

    print_success "SDDM theme $SDDM_THEME_NAME installed and configured."
else
    print_warning "Monochrome SDDM theme not found at $SDDM_THEME_SRC"
    log_message "SDDM theme folder missing. Skipping."
fi

# === Post-Install Instructions ===

print_info "\nPost-installation instructions:"
print_bold_blue "Set themes and icons:"
echo "   - Run 'nwg-look' to set GTK + icon theme (FlatColor + Papirus-Light-Mono)"
echo "   - Open 'kvantummanager' and select FlatColor"
echo "   - Run 'qt5ct' and 'qt6ct' to verify Qt apps match"
echo "   - Reboot to apply all theming and SDDM"

echo "------------------------------------------------------------------------"
