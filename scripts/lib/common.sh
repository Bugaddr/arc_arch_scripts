#!/usr/bin/env bash
#
# Common library for arc_arch_scripts
# Source this file in scripts that need shared functionality
#

# ---
# Colors and Messaging
# ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_BOLD='\033[1m'

# Print a colored message
# Usage: msg "${C_BLUE}" "Your message"
msg() {
    echo -e "${1}${C_BOLD}[*] ${2}${C_RESET}"
}

# Ask a yes/no question with [y/N] default
# Usage: if ask_yes_no "Continue?"; then ... fi
ask_yes_no() {
    local prompt="$1 [y/N]: "
    local response
    while true; do
        read -rp "$(echo -e "${C_YELLOW}${C_BOLD}[?] ${prompt}${C_RESET}")" response
        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]|"") return 1 ;;
            *) msg "${C_RED}" "Invalid input. Please enter 'y' or 'n'." ;;
        esac
    done
}

# Check if running as root
# Usage: require_root
require_root() {
    if [[ $EUID -ne 0 ]]; then
        msg "${C_RED}" "This script must be run as root."
        exit 1
    fi
}

# Check if NOT running as root (for user-level scripts)
# Usage: require_user
require_user() {
    if [[ $EUID -eq 0 ]]; then
        msg "${C_RED}" "This script should NOT be run as root."
        exit 1
    fi
}

# Install packages with pacman (skip already installed)
# Usage: pkg_install package1 package2 ...
pkg_install() {
    pacman -S --needed --noconfirm "$@"
}

# Remove packages completely (config + orphan deps)
# Usage: pkg_remove package1 package2 ...
pkg_remove() {
    pacman -Rcnsd --noconfirm "$@" 2>/dev/null || true
}

# Enable and start a systemd service
# Usage: service_enable servicename
service_enable() {
    systemctl enable --now "$1"
}

# Enable and start a user-level systemd service
# Usage: service_enable_user servicename
service_enable_user() {
    systemctl --user enable --now "$1"
}
