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

# Backgrounds
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

# ------------------------------------------------------------------------

# Starship Prompt
run_command "yay -S --sudoloop --noconfirm starship" "Install Starship - Prompt" "yes" "no"

STARSHIP_SRC="$REPO_DIR/configs/starship/starship.toml"
STARSHIP_DEST="$CONFIG_DIR/starship.toml"

if [ -f "$STARSHIP_SRC" ]; then
    run_command "cp \"$STARSHIP_SRC\" \"$STARSHIP_DEST\"" "Copy Starship config to $CONFIG_DIR" "yes" "no"
    run_command "chown $SUDO_USER:$SUDO_USER \"$STARSHIP_DEST\"" "Fix ownership for starship.toml" "no" "yes"
else
    print_warning "Starship config file not found: $STARSHIP_SRC"
fi

# Add Starship init to shell configs
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

# ------------------------------------------------------------------------

# Install Papirus Icon Theme
run_command "pacman -S --noconfirm papirus-icon-theme" "Install Papirus Icon Theme (Stable)" "yes" "yes"

# GTK settings
GTK3_CONFIG_DIR="$USER_HOME/.config/gtk-3.0"
GTK4_CONFIG_DIR="$USER_HOME/.config/gtk-4.0"

run_command "mkdir -p \"$GTK3_CONFIG_DIR\" \"$GTK4_CONFIG_DIR\"" "Ensure GTK config dirs exist" "no" "no"

GTK_SETTINGS_CONTENT="[Settings]
gtk-theme-name=FlatColor
gtk-icon-theme-name=Papirus
gtk-font-name=JetBrainsMono 10"

echo "$GTK_SETTINGS_CONTENT" | tee "$GTK3_CONFIG_DIR/settings.ini" "$GTK4_CONFIG_DIR/settings.ini" > /dev/null
run_command "chown -R $SUDO_USER:$SUDO_USER \"$GTK3_CONFIG_DIR\" \"$GTK4_CONFIG_DIR\"" "Fix ownership for GTK settings" "no" "yes"

# ------------------------------------------------------------------------
# Thunar theming via papirus-folders
TMP_DIR=$(mktemp -d -t papirus-folders-XXXXXX)

if [ -d "$TMP_DIR" ]; then
    run_command "git clone https://github.com/PapirusDevelopmentTeam/papirus-folders.git \"$TMP_DIR\"" "Clone papirus-folders repo" "yes" "no"

    if [ -f "$TMP_DIR/install.sh" ]; then
        run_command "sudo bash \"$TMP_DIR/install.sh\"" "Run papirus-folders install script" "yes" "yes"
        run_command "papirus-folders -C grey --theme Papirus-Dark" "Apply grey folder icons for Papirus-Dark" "yes" "no"
    else
        print_error "Install script missing in papirus-folders repo."
    fi

    run_command "rm -rf \"$TMP_DIR\"" "Clean up temporary folder after install" "no" "yes"
else
    print_error "Failed to create temporary directory: $TMP_DIR"
fi

# ------------------------------------------------------------------------
# SDDM Monochrome Theme
MONO_SDDM_REPO="https://github.com/pwyde/monochrome-kde.git"
MONO_SDDM_TEMP="/tmp/monochrome-kde"
MONO_THEME_NAME="monochrome"

run_command "git clone --depth=1 \"$MONO_SDDM_REPO\" \"$MONO_SDDM_TEMP\"" "Clone monochrome KDE repo" "yes" "no"
run_command "sudo cp -r \"$MONO_SDDM_TEMP/sddm/themes/$MONO_THEME_NAME\" \"/usr/share/sddm/themes/$MONO_THEME_NAME\"" "Copy monochrome SDDM theme" "yes" "no"
run_command "sudo chown -R root:root \"/usr/share/sddm/themes/$MONO_THEME_NAME\"" "Set ownership for monochrome theme" "no" "yes"
run_command "sudo mkdir -p /etc/sddm.conf.d" "Ensure SDDM config directory exists" "no" "no"
run_command "sudo bash -c 'echo -e \"[Theme]\\nCurrent=$MONO_THEME_NAME\" > /etc/sddm.conf.d/10-theme.conf'" "Set monochrome theme in SDDM config" "yes" "yes"
run_command "rm -rf \"$MONO_SDDM_TEMP\"" "Cleanup cloned mono repo" "no" "yes"

echo "------------------------------------------------------------------------"
