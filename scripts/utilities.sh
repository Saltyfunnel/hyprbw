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

USER_HOME="/home/$SUDO_USER"
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
    run_command "chown -R $SUDO_USER:$SUDO_USER \"$dest\"" "Fix ownership for $dest" "no" "yes"
}

# ----------------- APPLICATIONS ------------------

run_command "pacman -S --noconfirm waybar" "Install Waybar" "yes"
copy_as_user "$REPO_DIR/configs/waybar" "$CONFIG_DIR/waybar"

run_command "yay -S --sudoloop --noconfirm tofi" "Install Tofi" "yes" "no"
copy_as_user "$REPO_DIR/configs/tofi" "$CONFIG_DIR/tofi"

run_command "pacman -S --noconfirm cliphist" "Install Cliphist" "yes"
run_command "yay -S --sudoloop --noconfirm swww" "Install swww" "yes" "no"
copy_as_user "$ASSETS_SRC/backgrounds" "$ASSETS_DEST/backgrounds"

run_command "yay -S --sudoloop --noconfirm hyprpicker" "Install Hyprpicker" "yes" "no"
run_command "yay -S --sudoloop --noconfirm hyprlock" "Install Hyprlock" "yes" "no"
copy_as_user "$REPO_DIR/configs/hypr" "$CONFIG_DIR/hypr"

run_command "yay -S --sudoloop --noconfirm grimblast" "Install Grimblast" "yes" "no"
run_command "yay -S --sudoloop --noconfirm hypridle" "Install Hypridle" "yes" "no"

# ----------------- STARSHIP ------------------

run_command "yay -S --sudoloop --noconfirm starship" "Install Starship" "yes" "no"
STARSHIP_SRC="$REPO_DIR/configs/starship/starship.toml"
STARSHIP_DEST="$CONFIG_DIR/starship.toml"

if [ -f "$STARSHIP_SRC" ]; then
    run_command "cp \"$STARSHIP_SRC\" \"$STARSHIP_DEST\"" "Copy Starship config" "yes" "no"
    run_command "chown $SUDO_USER:$SUDO_USER \"$STARSHIP_DEST\"" "Fix ownership for Starship config" "no" "yes"
else
    print_warning "Starship config not found: $STARSHIP_SRC"
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

# ----------------- GTK THEME ------------------

run_command "pacman -S --noconfirm papirus-icon-theme" "Install Papirus Icon Theme" "yes" "yes"

GTK3_CONFIG_DIR="$USER_HOME/.config/gtk-3.0"
GTK4_CONFIG_DIR="$USER_HOME/.config/gtk-4.0"

run_command "mkdir -p \"$GTK3_CONFIG_DIR\" \"$GTK4_CONFIG_DIR\"" "Ensure GTK config dirs exist" "no" "no"

GTK_SETTINGS_CONTENT="[Settings]
gtk-theme-name=FlatColor
gtk-icon-theme-name=Papirus
gtk-font-name=JetBrainsMono 10"

echo "$GTK_SETTINGS_CONTENT" | tee "$GTK3_CONFIG_DIR/settings.ini" "$GTK4_CONFIG_DIR/settings.ini" > /dev/null
run_command "chown -R $SUDO_USER:$SUDO_USER \"$GTK3_CONFIG_DIR\" \"$GTK4_CONFIG_DIR\"" "Fix ownership for GTK settings" "no" "yes"

# ----------------- PAPIRUS-FOLDERS FIX (GREY) ------------------

TEMP_PAPIRUS_DIR=$(mktemp -d -t papirus-folders-XXXXXX)

run_command "git clone https://github.com/PapirusDevelopmentTeam/papirus-folders.git \"$TEMP_PAPIRUS_DIR\"" "Clone papirus-folders repo" "yes" "no"
run_command "cd \"$TEMP_PAPIRUS_DIR\" && sudo ./install.sh" "Install papirus-folders tool" "yes" "yes"
run_command "papirus-folders -C grey --theme Papirus-Dark" "Apply grey Papirus folder color" "yes" "no"
run_command "rm -rf \"$TEMP_PAPIRUS_DIR\"" "Cleanup papirus-folders temp dir" "no" "yes"

# ----------------- SDDM MONOCHROME ------------------

MONO_SDDM_REPO="https://github.com/pwyde/monochrome-kde.git"
MONO_SDDM_TEMP="/tmp/monochrome-kde"
MONO_THEME_NAME="monochrome"

if [ -d "$MONO_SDDM_TEMP" ]; then
    print_warning "Removing existing $MONO_SDDM_TEMP"
    rm -rf "$MONO_SDDM_TEMP"
fi

run_command "git clone --depth=1 \"$MONO_SDDM_REPO\" \"$MONO_SDDM_TEMP\"" "Clone monochrome KDE repo" "yes" "no"
run_command "sudo cp -r \"$MONO_SDDM_TEMP/sddm/themes/$MONO_THEME_NAME\" \"/usr/share/sddm/themes/$MONO_THEME_NAME\"" "Copy SDDM theme" "yes" "no"
run_command "sudo chown -R root:root \"/usr/share/sddm/themes/$MONO_THEME_NAME\"" "Fix ownership for SDDM theme" "no" "yes"
run_command "sudo mkdir -p /etc/sddm.conf.d" "Ensure SDDM config dir exists" "no" "no"
run_command "sudo bash -c 'echo -e \"[Theme]\\nCurrent=$MONO_THEME_NAME\" > /etc/sddm.conf.d/10-theme.conf'" "Set SDDM theme" "yes" "yes"
run_command "rm -rf \"$MONO_SDDM_TEMP\"" "Cleanup monochrome-kde temp dir" "no" "yes"

echo "------------------------------------------------------------------------"
print_success "Utilities installation complete and configured successfully."
