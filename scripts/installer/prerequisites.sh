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

log_message "Installation started for prerequisites section"
print_info "\nStarting prerequisites setup..."

run_command "pacman -Syyu --noconfirm" "Update package database and upgrade packages (Recommended)" "yes"

# --- Yay Installation ---
if ! command -v yay &> /dev/null; then
    print_info "YAY not found, installing..."

    run_command "pacman -S --noconfirm --needed git base-devel" "Install Git and base-devel for yay" "yes"

    run_command "git clone https://aur.archlinux.org/yay.git /tmp/yay" "Clone yay repo" "no" "no"

    run_command "chown -R $SUDO_USER:$SUDO_USER /tmp/yay" "Fix yay folder ownership" "no" "no"

    run_command "cd /tmp/yay && sudo -u $SUDO_USER makepkg -si --noconfirm" "Build and install yay" "no" "no"

    run_command "rm -rf /tmp/yay" "Clean up yay build folder" "no" "no"
else
    print_success "YAY is already installed."
fi

# --- System Packages ---
run_command "pacman -S --noconfirm pipewire wireplumber pamixer brightnessctl" "Configuring audio and brightness (Recommended)" "yes"

run_command "pacman -S --noconfirm ttf-cascadia-code-nerd ttf-cascadia-mono-nerd ttf-fira-code ttf-fira-mono ttf-fira-sans ttf-firacode-nerd ttf-iosevka-nerd ttf-iosevkaterm-nerd ttf-jetbrains-mono-nerd ttf-jetbrains-mono ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono" "Installing Nerd Fonts and Symbols (Recommended)" "yes"

run_command "pacman -S --noconfirm sddm && systemctl enable sddm.service" "Install and enable SDDM (Recommended)" "yes"

run_command "yay -S --sudoloop --noconfirm firefox" "Install Firefox browser" "yes" "no"

# --- Terminal, Editor, Tools ---
run_command "pacman -S --noconfirm kitty" "Install Kitty (Recommended)" "yes"
run_command "pacman -S --noconfirm nano" "Install nano" "yes"
run_command "pacman -S --noconfirm tar" "Install tar for extracting files (Must)/needed for copying themes" "yes"
run_command "pacman -S --noconfirm gnome-disk-utility" "Install disks" "yes"
run_command "pacman -S --noconfirm code" "Install VSCode" "yes"
run_command "pacman -S --noconfirm mpv" "Install MPV" "yes"
# Install Thunar file manager and related extras
run_command "pacman -S --noconfirm thunar thunar-archive-plugin thunar-volman tumbler ffmpegthumbnailer file-roller" "Install Thunar with extra features" "yes"

# GVFS backends for mounting USBs, MTP devices, Samba, etc.
run_command "pacman -S --noconfirm gvfs gvfs-mtp gvfs-gphoto2 gvfs-smb" "Install GVFS backends for Thunar" "yes"



echo "------------------------------------------------------------------------"
