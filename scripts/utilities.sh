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

# Function to safely copy directory as the user
copy_as_user() {
    local src="$1"
    local dest="$2"

    if [ ! -d "$src" ]; then
        print_warning "Source folder not found: $src"
        return 1
    fi

    # Make sure destination exists
    run_command "mkdir -p \"$dest\"" "Create destination directory $dest" "no" "no"

    # Copy content as the user
    run_command "cp -r \"$src\"/* \"$dest\"" "Copy from $src to $dest" "yes" "no"

    # Fix ownership recursively to the user
    run_command "chown -R $SUDO_USER:$SUDO_USER \"$dest\"" "Fix ownership for $dest" "no" "yes"
}

# Waybar
run_command "pacman -S --noconfirm waybar" "Install Waybar - Status Bar" "yes"
copy_as_user "$REPO_DIR/configs/waybar" "$CONFIG_DIR/waybar"

# Tofi
run_command "yay -S --sudoloop --noconfirm tofi" "Install Tofi - Application Launcher" "yes" "no"
copy_as_user "$REPO_DIR/configs/tofi" "$CONFIG_DIR/tofi"

# Cliphist
run_command "pacman -S --noconfirm cliphist" "Install Cliphist - Clipboard Manager" "yes"

# SWWW
run_command "yay -S --sudoloop --noconfirm swww" "Install SWWW for wallpaper management" "yes" "no"

# Backgrounds (copy assets/backgrounds)
copy_as_user "$ASSETS_SRC/backgrounds" "$ASSETS_DEST/backgrounds"

# Hyprpicker
run_command "yay -S --sudoloop --noconfirm hyprpicker" "Install Hyprpicker - Color Picker" "yes" "no"

# Hyprlock
run_command "yay -S --sudoloop --noconfirm hyprlock" "Install Hyprlock - Screen Locker" "yes" "no"
copy_as_user "$REPO_DIR/configs/hypr" "$CONFIG_DIR/hypr"

# Grimblast
run_command "yay -S --sudoloop --noconfirm grimblast" "Install Grimblast - Screenshot tool" "yes" "no"

# Hypridle
run_command "yay -S --sudoloop --noconfirm hypridle" "Install Hypridle for idle management" "yes" "no"
# hypridle config copied above as part of hypr folder

echo "------------------------------------------------------------------------"
