#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/helper.sh"

log_message "Installation started for utilities section"
print_info "\nStarting utilities setup..."

# Detect the user running sudo
USER_NAME="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$USER_NAME")

CONFIG_DIR="$USER_HOME/.config"
REPO_DIR="$USER_HOME/hyprbw"
ASSETS_SRC="$REPO_DIR/assets"
ASSETS_DEST="$CONFIG_DIR/assets"

copy_as_user() {
    local src="$1"
    local dest="$2"

    if [ ! -d "$src" ]; then
        print_warning "Source folder not found: $src"
        return 1
    fi

    run_command "mkdir -p \"$dest\"" "Create destination directory $dest" "no" "no"
    run_command "cp -r \"$src\"/* \"$dest\"" "Copy from $src to $dest" "yes" "no"
    run_command "chown -R $USER_NAME:$USER_NAME \"$dest\"" "Fix ownership for $dest" "no" "yes"
}

# Waybar
run_command "pacman -S --noconfirm waybar" "Install Waybar - Status Bar" "yes"
copy_as_user "$REPO_DIR/configs/waybar" "$CONFIG_DIR/waybar"

# Tofi
run_command "yay -S --sudoloop --noconfirm tofi" "Install Tofi - Application Launcher" "yes" "no"
copy_as_user "$REPO_DIR/configs/tofi" "$CONFIG_DIR/tofi"

# fastfetch
run_command "yay -S --sudoloop --noconfirm fastfetch" "Install fastfetch" "yes" "no"
copy_as_user "$REPO_DIR/configs/fastfetch" "$CONFIG_DIR/fastfetch"

add_fastfetch_to_shell() {
    local shell_rc="$1"
    local shell_rc_path="$USER_HOME/$shell_rc"
    local fastfetch_line='fastfetch'

    if [ -f "$shell_rc_path" ]; then
        if ! grep -qF "$fastfetch_line" "$shell_rc_path"; then
            echo -e "\n# Run fastfetch on terminal start\n$fastfetch_line" >> "$shell_rc_path"
            run_command "chown $USER_NAME:$USER_NAME \"$shell_rc_path\"" "Fix ownership for $shell_rc" "no" "yes"
            print_info "Added fastfetch run to $shell_rc"
        fi
    fi
}

add_fastfetch_to_shell ".bashrc"
add_fastfetch_to_shell ".zshrc"

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

# Starship Prompt
run_command "yay -S --sudoloop --noconfirm starship" "Install Starship - Prompt" "yes" "no"

STARSHIP_SRC="$REPO_DIR/configs/starship/starship.toml"
STARSHIP_DEST="$CONFIG_DIR/starship.toml"

if [ -f "$STARSHIP_SRC" ]; then
    run_command "cp \"$STARSHIP_SRC\" \"$STARSHIP_DEST\"" "Copy Starship config to $CONFIG_DIR" "yes" "no"
    run_command "chown $USER_NAME:$USER_NAME \"$STARSHIP_DEST\"" "Fix ownership for starship.toml" "no" "yes"
else
    print_warning "Starship config file not found: $STARSHIP_SRC"
fi

add_starship_to_shell() {
    local shell_rc="$1"
    local shell_name="$2"
    local shell_rc_path="$USER_HOME/$shell_rc"
    local starship_line='eval "$(starship init '"$shell_name"')"'

    if [ -f "$shell_rc_path" ]; then
        if ! grep -qF "$starship_line" "$shell_rc_path"; then
            echo -e "\n$starship_line" >> "$shell_rc_path"
            run_command "chown $USER_NAME:$USER_NAME \"$shell_rc_path\"" "Fix ownership for $shell_rc" "no" "yes"
            print_info "Added Starship init to $shell_rc"
        fi
    fi
}

add_starship_to_shell ".bashrc" "bash"
add_starship_to_shell ".zshrc" "zsh"

# Install Papirus icon theme
run_command "pacman -S --noconfirm papirus-icon-theme" "Install Papirus Icon Theme" "yes" "yes"

# Install papirus-folders if missing
if ! command -v papirus-folders &>/dev/null; then
    TMP_DIR=$(mktemp -d)
    run_command "git clone https://github.com/PapirusDevelopmentTeam/papirus-folders.git \"$TMP_DIR\"" "Clone papirus-folders"
    run_command "install -Dm755 \"$TMP_DIR/papirus-folders\" /usr/local/bin/papirus-folders" "Install papirus-folders binary"
    rm -rf "$TMP_DIR"
fi

# Set folder color to grey (run under user's DBus session)
run_command "sudo -u $USER_NAME dbus-launch papirus-folders -C grey --theme Papirus-Dark" "Set Papirus folder color to grey" "yes" "no"

# GTK config
GTK3_CONFIG_DIR="$USER_HOME/.config/gtk-3.0"
GTK4_CONFIG_DIR="$USER_HOME/.config/gtk-4.0"
run_command "mkdir -p \"$GTK3_CONFIG_DIR\" \"$GTK4_CONFIG_DIR\"" "Ensure GTK config dirs exist" "no" "no"

GTK_SETTINGS_CONTENT="[Settings]
gtk-theme-name=FlatColor
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrainsMono 10"

echo "$GTK_SETTINGS_CONTENT" | sudo -u $USER_NAME tee "$GTK3_CONFIG_DIR/settings.ini" "$GTK4_CONFIG_DIR/settings.ini" > /dev/null
run_command "chown -R $USER_NAME:$USER_NAME \"$GTK3_CONFIG_DIR\" \"$GTK4_CONFIG_DIR\"" "Fix ownership for GTK settings" "no" "yes"

# Set icon theme using gsettings with dbus
run_command "sudo -u $USER_NAME dbus-launch gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'" "Apply Papirus-Dark using gsettings" "yes" "no"

# SDDM Theme
MONO_SDDM_REPO="https://github.com/pwyde/monochrome-kde.git"
MONO_SDDM_TEMP="/tmp/monochrome-kde"
MONO_THEME_NAME="monochrome"

run_command "git clone --depth=1 \"$MONO_SDDM_REPO\" \"$MONO_SDDM_TEMP\"" "Clone monochrome KDE repo"
run_command "sudo cp -r \"$MONO_SDDM_TEMP/sddm/themes/$MONO_THEME_NAME\" \"/usr/share/sddm/themes/$MONO_THEME_NAME\"" "Copy monochrome SDDM theme"
run_command "sudo chown -R root:root \"/usr/share/sddm/themes/$MONO_THEME_NAME\"" "Set ownership for monochrome theme"
run_command "sudo mkdir -p /etc/sddm.conf.d" "Ensure SDDM config directory exists"
run_command "sudo bash -c 'echo -e \"[Theme]\\nCurrent=$MONO_THEME_NAME\" > /etc/sddm.conf.d/10-theme.conf'" "Apply SDDM theme"
run_command "rm -rf \"$MONO_SDDM_TEMP\"" "Cleanup cloned repo"

echo "------------------------------------------------------------------------"
print_info "All utilities installed successfully!"
