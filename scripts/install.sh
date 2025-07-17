#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(realpath "$SCRIPT_DIR/..")"
USER_HOME="/home/${SUDO_USER:-$USER}"
export SUDO_USER  # needed for helper functions

source "$SCRIPT_DIR/helper.sh"

check_root
check_os

print_bold_blue "\n🚀 Starting Full Hyprland Setup"
echo "-------------------------------------"

# Run each phase script
for phase in prerequisites utilities gpu themes final; do
  if [[ -x "$SCRIPT_DIR/$phase.sh" ]]; then
    print_header "Executing $phase.sh"
    bash "$SCRIPT_DIR/$phase.sh"
  else
    print_warning "Phase script '$phase.sh' not found or not executable. Skipping."
  fi
done

print_bold_blue "\n✅ Setup Complete! You can now reboot to apply changes."
