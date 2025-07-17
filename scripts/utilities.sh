#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(realpath "$SCRIPT_DIR/..")"
USER_HOME="/home/$SUDO_USER"

source "$SCRIPT_DIR/helper.sh"

check_root
check_os

print_header "Starting utilities setup..."

if ! command -v yay &>/dev/null; then
  print_error "Yay is not installed. Please run prerequisites.sh first."
  exit 1
fi

# Packages to install with pacman or yay
PACMAN_PKGS=(waybar cliphist)
AUR_PKGS=(tofi swww hyprpicker hyprlock grimblast hypridle)

# Install pacman packages
for pkg in "${PACMAN_PKGS[@]}"; do
  run_command "pacman -S --noconfirm $pkg" "Install $pkg" "yes"
done

# Install AUR packages with yay
for pkg in "${AUR_PKGS[@]}"; do
  run_command "yay -S --sudoloop --noconfirm $pkg" "Install $pkg" "yes" "no"
done

# Copy configs with ownership fix
copy_and_chown() {
  local src="$1"
  local dst="$2"
  if [[ -e "$src" ]]; then
    run_command "mkdir -p $dst" "Create directory $dst" "no" "no"
    run_command "cp -r $src/* $dst/" "Copy configs from $src to $dst" "yes" "no"
    run_command "chown -R $SUDO_USER:$SUDO_USER $dst" "Fix ownership for $dst" "no" "yes"
  else
    print_warning "Source directory $src does not exist. Skipping."
  fi
}

copy_and_chown "$REPO_ROOT/configs/waybar" "$USER_HOME/.config/waybar"
copy_and_chown "$REPO_ROOT/configs/tofi" "$USER_HOME/.config/tofi"

# Backgrounds
BG_SRC="$REPO_ROOT/assets/backgrounds"
BG_DST="$USER_HOME/.config/assets/backgrounds"
if [[ -d "$BG_SRC" ]]; then
  run_command "mkdir -p $BG_DST" "Create backgrounds directory" "no" "no"
  run_command "cp -r $BG_SRC/* $BG_DST/" "Copy background images" "yes" "no"
  run_command "chown -R $SUDO_USER:$SUDO_USER $BG_DST" "Fix ownership for backgrounds" "no" "yes"
else
  print_warning "Backgrounds directory missing: $BG_SRC"
fi

# Hyprlock and Hypridle configs
run_command "mkdir -p $USER_HOME/.config/hypr" "Create hypr config directory" "no" "no"

if [[ -f "$REPO_ROOT/configs/hypr/hyprlock.conf" ]]; then
  run_command "cp $REPO_ROOT/configs/hypr/hyprlock.conf $USER_HOME/.config/hypr/" "Copy hyprlock.conf" "yes" "no"
  run_command "chown $SUDO_USER:$SUDO_USER $USER_HOME/.config/hypr/hyprlock.conf" "Fix ownership hyprlock.conf" "no" "yes"
fi

if [[ -f "$REPO_ROOT/configs/hypr/hypridle.conf" ]]; then
  run_command "cp $REPO_ROOT/configs/hypr/hypridle.conf $USER_HOME/.config/hypr/" "Copy hypridle.conf" "yes" "no"
  run_command "chown $SUDO_USER:$SUDO_USER $USER_HOME/.config/hypr/hypridle.conf" "Fix ownership hypridle.conf" "no" "yes"
fi

echo "------------------------------------------------------------------------"
