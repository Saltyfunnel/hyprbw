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
    run_command "cp -r \"$src\"/* \"$dest\"" "Copy from $src to $dest" "yes" "no"
    run_command "chown -R $SUDO_USER:$SUDO_USER \"$dest\"" "Fix ownership for $dest" "no" "yes"
}

# Install Waybar
run_command "pacman -S --noconfirm waybar" "Install Waybar - Status Bar" "yes"
copy_as_user "$REPO_DIR/configs/waybar" "$CONFIG_DIR/waybar"

# Install Tofi
run_command "yay -S --sudoloop --noconfirm tofi" "Install Tofi - Application Launcher" "yes" "no"
copy_as_user "$REPO_DIR/configs/tofi" "$CONFIG_DIR/tofi"

# Install Cliphist
run_command "pacman -S --noconfirm cliphist" "Install Cliphist - Clipboard Manager" "yes"

# Install SWWW
run_command "yay -S --sudoloop --noconfirm swww" "Install SWWW for wallpaper management" "yes" "no"

# Copy Backgrounds
copy_as_user "$ASSETS_SRC/backgrounds" "$ASSETS_DEST/backgrounds"

# Install Hyprpicker
run_command "yay -S --sudoloop --noconfirm hyprpicker" "Install Hyprpicker - Color Picker" "yes" "no"

# Install Hyprlock and copy configs
run_command "yay -S --sudoloop --noconfirm hyprlock" "Install Hyprlock - Screen Locker" "yes" "no"
copy_as_user "$REPO_DIR/configs/hypr" "$CONFIG_DIR/hypr"

# Install Grimblast
run_command "yay -S --sudoloop --noconfirm grimblast" "Install Grimblast - Screenshot tool" "yes" "no"

# Install Hypridle
run_command "yay -S --sudoloop --noconfirm hypridle" "Install Hypridle for idle management" "yes" "no"

# Starship Prompt installation and config
run_command "yay -S --sudoloop --noconfirm starship" "Install Starship - Prompt" "yes" "no"

STARSHIP_SRC="$REPO_DIR/configs/starship/starship.toml"
STARSHIP_DEST="$CONFIG_DIR/starship.toml"

if [ -f "$STARSHIP_SRC" ]; then
    run_command "cp \"$STARSHIP_SRC\" \"$STARSHIP_DEST\"" "Copy Starship config to $CONFIG_DIR" "yes" "no"
    run_command "chown $SUDO_USER:$SUDO_USER \"$STARSHIP_DEST\"" "Fix ownership for starship.toml" "no" "yes"
else
    print_warning "Starship config file not found: $STARSHIP_SRC"
fi

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

# Install Papirus icon theme (run as root)
run_command "pacman -S --noconfirm papirus-icon-theme" "Install Papirus Icon Theme (Stable)" "yes" "yes"

# Install papirus-folders from GitHub with clean temp directory (fixed permission handling)
TMP_DIR=$(sudo mktemp -d)
sudo rm -rf "$TMP_DIR"
sudo git clone https://github.com/PapirusDevelopmentTeam/papirus-folders.git "$TMP_DIR"
sudo bash "$TMP_DIR/install.sh"
sudo rm -rf "$TMP_DIR"

# Define GTK config paths
GTK3_CONFIG_DIR="$USER_HOME/.config/gtk-3.0"
GTK4_CONFIG_DIR="$USER_HOME/.config/gtk-4.0"

# Ensure config directories exist (run as user)
run_command "mkdir -p \"$GTK3_CONFIG_DIR\" \"$GTK4_CONFIG_DIR\"" "Ensure GTK config dirs exist" "no" "no"

# Apply theme settings (run as user)
GTK_SETTINGS_CONTENT="[Settings]
gtk-theme-name=FlatColor
gtk-icon-theme-name=Papirus
gtk-font-name=JetBrainsMono 10"

echo "$GTK_SETTINGS_CONTENT" | tee "$GTK3_CONFIG_DIR/settings.ini" "$GTK4_CONFIG_DIR/settings.ini" > /dev/null

# Fix ownership so user owns the files (run as root)
run_command "chown -R $SUDO_USER:$SUDO_USER \"$GTK3_CONFIG_DIR\" \"$GTK4_CONFIG_DIR\"" "Fix ownership for GTK settings" "no" "yes"

# Set GTK/GNOME icon theme to Papirus-Dark
run_command "sudo -u $SUDO_USER gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'" "Set icon theme to Papirus-Dark" "no" "no"


# ------------------------------------------------------------------------

# SDDM Monochrome Theme (KDE repository)
MONO_SDDM_REPO="https://github.com/pwyde/monochrome-kde.git"
MONO_SDDM_TEMP="/tmp/monochrome-kde"
MONO_THEME_NAME="monochrome"  # folder inside sddm/themes

# Clone the repository (no root needed)
run_command "git clone --depth=1 \"$MONO_SDDM_REPO\" \"$MONO_SDDM_TEMP\"" "Clone monochrome KDE repo" "yes" "no"

# Copy SDDM theme folder (needs root)
run_command "sudo cp -r \"$MONO_SDDM_TEMP/sddm/themes/$MONO_THEME_NAME\" \"/usr/share/sddm/themes/$MONO_THEME_NAME\"" "Copy monochrome SDDM theme" "yes" "no"

# Fix ownership (needs root)
run_command "sudo chown -R root:root \"/usr/share/sddm/themes/$MONO_THEME_NAME\"" "Set ownership for monochrome theme" "no" "yes"

# Apply the theme in SDDM (needs root)
run_command "sudo mkdir -p /etc/sddm.conf.d" "Ensure SDDM config directory exists" "no" "no"
run_command "sudo bash -c 'echo -e \"[Theme]\\nCurrent=$MONO_THEME_NAME\" > /etc/sddm.conf.d/10-theme.conf'" "Set monochrome theme in SDDM config" "yes" "yes"

# Cleanup (no root needed)
run_command "rm -rf \"$MONO_SDDM_TEMP\"" "Cleanup cloned mono repo" "no" "yes"

echo "------------------------------------------------------------------------"
