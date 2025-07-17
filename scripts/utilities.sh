#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/helper.sh"

log_message "Installation started for utilities section"
print_info "\nStarting utilities setup..."

# Ensure yay is installed
if ! command -v yay &> /dev/null; then
    print_error "YAY is not installed. Please ensure prerequisites.sh installs yay successfully."
    exit 1
fi

# Define user's home paths
USER_HOME="/home/$SUDO_USER"
CONFIG_DIR="$USER_HOME/.config"
REPO_DIR="$USER_HOME/hyprbw"
ASSETS_SRC="$REPO_DIR/assets"
ASSETS_DEST="$CONFIG_DIR/assets"

# Waybar
run_command "pacman -S --noconfirm waybar" "Install Waybar - Status Bar" "yes"
run_command "cp -r $REPO_DIR/configs/waybar $CONFIG_DIR/" "Copy Waybar config" "yes" "no"

# Tofi
run_command "yay -S --sudoloop --noconfirm tofi" "Install Tofi - Application Launcher" "yes" "no"
run_command "cp -r $REPO_DIR/configs/tofi $CONFIG_DIR/" "Copy Tofi config(s)" "yes" "no"

# Cliphist
run_command "pacman -S --noconfirm cliphist" "Install Cliphist - Clipboard Manager" "yes"

# SWWW
run_command "yay -S --sudoloop --noconfirm swww" "Install SWWW for wallpaper management" "yes" "no"

# Backgrounds (ensure target dir & copy as user)
run_command "mkdir -p $ASSETS_DEST/backgrounds" "Create backgrounds directory" "no" "no"
if [ -d "$ASSETS_SRC/backgrounds" ]; then
    run_command "cp -r $ASSETS_SRC/backgrounds/* $ASSETS_DEST/backgrounds/" "Copy background images" "yes" "no"
else
    print_warning "Backgrounds folder not found at $ASSETS_SRC/backgrounds"
    log_message "Backgrounds not copied: missing folder."
fi

# Hyprpicker
run_command "yay -S --sudoloop --noconfirm hyprpicker" "Install Hyprpicker - Color Picker" "yes" "no"

# Hyprlock
run_command "yay -S --sudoloop --noconfirm hyprlock" "Install Hyprlock - Screen Locker" "yes" "no"
run_command "mkdir -p $CONFIG_DIR/hypr" "Ensure Hypr config dir exists" "no" "no"
run_command "cp -r $REPO_DIR/configs/hypr/hyprlock.conf $CONFIG_DIR/hypr/" "Copy Hyprlock config" "yes" "no"

# Grimblast
run_command "yay -S --sudoloop --noconfirm grimblast" "Install Grimblast - Screenshot tool" "yes" "no"

# Hypridle
run_command "yay -S --sudoloop --noconfirm hypridle" "Install Hypridle for idle management" "yes" "no"
run_command "cp -r $REPO_DIR/configs/hypr/hypridle.conf $CONFIG_DIR/hypr/" "Copy Hypridle config" "yes" "no"

echo "------------------------------------------------------------------------"
