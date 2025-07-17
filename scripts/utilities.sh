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

    run_command "mkdir -p \"$dest\"" "Create destination directory $dest" "no" "no"
    run_command "cp -r \"$src\"/* \"$dest\"" "Copy from $src to $dest" "yes" "no"
    run_command "chown -R $SUDO_USER:$SUDO_USER \"$dest\"" "Fix ownership for $dest" "no" "yes"
}

# Install utilities
run_command "pacman -S --noconfirm waybar cliphist papirus-icon-theme" "Install core utilities" "yes"
run_command "yay -S --sudoloop --noconfirm tofi swww hyprpicker hyprlock grimblast hypridle starship" "Install yay utilities" "yes" "no"

# Copy config folders
copy_as_user "$REPO_DIR/configs/waybar" "$CONFIG_DIR/waybar"
copy_as_user "$REPO_DIR/configs/tofi" "$CONFIG_DIR/tofi"
copy_as_user "$REPO_DIR/configs/hypr" "$CONFIG_DIR/hypr"
copy_as_user "$ASSETS_SRC/backgrounds" "$ASSETS_DEST/backgrounds"

# Copy Starship config
STARSHIP_SRC="$REPO_DIR/configs/starship/starship.toml"
STARSHIP_DEST="$CONFIG_DIR/starship.toml"

if [ -f "$STARSHIP_SRC" ]; then
    run_command "cp \"$STARSHIP_SRC\" \"$STARSHIP_DEST\"" "Copy Starship config to $CONFIG_DIR" "yes" "no"
    run_command "chown $SUDO_USER:$SUDO_USER \"$STARSHIP_DEST\"" "Fix ownership for starship.toml" "no" "yes"
else
    print_warning "Starship config file not found: $STARSHIP_SRC"
fi

# Add Starship to shell configs
add_starship_to_shell() {
    local shell_rc="$1"
    local shell_name="$2"
    local shell_rc_path="$USER_HOME/$shell_rc"
    local starship_line='eval "$(starship init '"$shell_name"')"'

    if [ -f "$shell_rc_path" ]; then
        if ! grep -q "$starship_line" "$shell_rc_path"; then
            echo -e "\n$starship_line" >> "$shell_rc_path"
            run_command "chown $SUDO_USER:$SUDO_USER \"$shell_rc_path\"" "Fix ownership for $shell_rc" "no" "yes"
            print_info "Added Starship init to $shell_rc"
        fi
    fi
}

add_starship_to_shell ".bashrc" "bash"
add_starship_to_shell ".zshrc" "zsh"

# GTK Theme Settings
GTK3_CONFIG_DIR="$USER_HOME/.config/gtk-3.0"
GTK4_CONFIG_DIR="$USER_HOME/.config/gtk-4.0"

run_command "mkdir -p \"$GTK3_CONFIG_DIR\" \"$GTK4_CONFIG_DIR\"" "Ensure GTK config dirs exist" "no" "no"

GTK_SETTINGS_CONTENT="[Settings]
gtk-theme-name=FlatColor
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrainsMono 10"

echo "$GTK_SETTINGS_CONTENT" | tee "$GTK3_CONFIG_DIR/settings.ini" "$GTK4_CONFIG_DIR/settings.ini" > /dev/null
run_command "chown -R $SUDO_USER:$SUDO_USER \"$GTK3_CONFIG_DIR\" \"$GTK4_CONFIG_DIR\"" "Fix ownership for GTK settings" "no" "yes"

# -----------------------------------------------------------------------------
# Papirus Folder Color & Icon Fix
# -----------------------------------------------------------------------------

# Ensure DBus is available
if ! pidof dbus-daemon > /dev/null; then
    run_command "dbus-daemon --session --fork" "Start DBus session"
fi

# Install papirus-folders if not present
PAPIRUS_FOLDER_TOOL="/usr/local/bin/papirus-folders"
if [ ! -f "$PAPIRUS_FOLDER_TOOL" ]; then
    TEMP_DIR=$(mktemp -d)
    run_command "git clone --depth=1 https://github.com/PapirusDevelopmentTeam/papirus-folders.git \"$TEMP_DIR\"" "Clone papirus-folders repo"
    run_command "install -Dm755 \"$TEMP_DIR/papirus-folders\" \"$PAPIRUS_FOLDER_TOOL\"" "Install papirus-folders tool"
    run_command "rm -rf \"$TEMP_DIR\"" "Cleanup papirus-folders temp dir"
fi

# Set folder color to grey in Papirus-Dark
run_command "papirus-folders -C grey --theme Papirus-Dark" "Apply 'grey' Papirus folder color"

# Force icon theme (important for Thunar/GTK apps)
run_command "gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'" "Set GTK icon theme via gsettings"

# -----------------------------------------------------------------------------
# SDDM Theme
# -----------------------------------------------------------------------------

MONO_SDDM_REPO="https://github.com/pwyde/monochrome-kde.git"
MONO_SDDM_TEMP="/tmp/monochrome-kde"
MONO_THEME_NAME="monochrome"

run_command "git clone --depth=1 \"$MONO_SDDM_REPO\" \"$MONO_SDDM_TEMP\"" "Clone monochrome KDE repo"
run_command "cp -r \"$MONO_SDDM_TEMP/sddm/themes/$MONO_THEME_NAME\" \"/usr/share/sddm/themes/$MONO_THEME_NAME\"" "Copy monochrome SDDM theme"
run_command "chown -R root:root \"/usr/share/sddm/themes/$MONO_THEME_NAME\"" "Set ownership for monochrome theme"

run_command "mkdir -p /etc/sddm.conf.d" "Ensure SDDM config directory exists"
run_command "bash -c 'echo -e \"[Theme]\\nCurrent=$MONO_THEME_NAME\" > /etc/sddm.conf.d/10-theme.conf'" "Set monochrome theme in SDDM config"

run_command "rm -rf \"$MONO_SDDM_TEMP\"" "Cleanup cloned mono repo"

echo "------------------------------------------------------------------------"
echo "✅ Utilities install complete! Papirus folder color and icon theme should be applied."
