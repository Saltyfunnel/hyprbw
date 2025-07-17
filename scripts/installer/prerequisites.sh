#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(realpath "$SCRIPT_DIR/..")
USER_HOME="/home/$SUDO_USER"

source "$SCRIPT_DIR/helper.sh"

check_root
check_os

log_message "Installation started for prerequisites section"
print_info "\nStarting prerequisites setup..."

run_command "pacman -Syyu --noconfirm" "Update package database and upgrade packages (Recommended)" "yes"

# Yay installation
if ! command -v yay &>/dev/null; then
  print_info "Yay not found, installing..."
  run_command "pacman -S --noconfirm --needed git base-devel" "Install Git and base-devel for yay" "yes"
  run_command "git clone https://aur.archlinux.org/yay.git /tmp/yay" "Clone yay repo" "no" "no"
  run_command "chown -R $SUDO_USER:$SUDO_USER /tmp/yay" "Fix yay folder ownership" "no" "no"
  run_command "cd /tmp/yay && sudo -u $SUDO_USER makepkg -si --noconfirm" "Build and install yay" "no" "no"
  run_command "rm -rf /tmp/yay" "Clean up yay build folder" "no" "no"
else
  print_success "Yay is already installed."
fi

# Packages array for easy maintenance
PKGS=(
  pipewire wireplumber pamixer brightnessctl
  ttf-cascadia-code-nerd ttf-cascadia-mono-nerd ttf-fira-code ttf-fira-mono ttf-fira-sans ttf-firacode-nerd ttf-iosevka-nerd ttf-iosevkaterm-nerd ttf-jetbrains-mono-nerd ttf-jetbrains-mono
  ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono
  sddm
  kitty nano tar gnome-disk-utility code mpv
  thunar thunar-archive-plugin thunar-volman tumbler ffmpegthumbnailer file-roller
  gvfs gvfs-mtp gvfs-gphoto2 gvfs-smb
)

run_command "pacman -S --noconfirm ${PKGS[*]}" "Install system packages (Recommended)" "yes"

# Enable sddm service
run_command "systemctl enable sddm.service" "Enable SDDM display manager" "yes"

# Install Firefox via yay (AUR)
run_command "yay -S --sudoloop --noconfirm firefox" "Install Firefox browser" "yes" "no"

echo "------------------------------------------------------------------------"
