#!/bin/bash

# =====================================================
# Post Optimiztion for Arch Linux. Part 5
# =====================================================

# Turn on strong mode for bash
set -e  # Exit by any error
set -u  # Only static variable

# Colors for output messages
BLUE="\e[1;34m"
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
RESET="\e[0m"

# INFO message
log_message() {
    echo -e "${BLUE}[INFO] $1${RESET}"
}

# ERROR message
log_error() {
    echo -e "${RED}[ERROR] $1${RESET}" >&2
}

# SUCCESS message
log_success() {
    echo -e "${GREEN}[SUCCESS] $1${RESET}"
}

# WARNING message
log_warning() {
    echo -e "${YELLOW}[WARNING] $1${RESET}"
}

# Check superuser
if [[ $EUID -ne 0 ]]; then
    log_error "This script MUST be run with superuser rights"
    echo "Use: sudo $0"
    exit 1
fi

# Delete lib32 packages
delete_lib32() {
    log_message "Delete all lib32 packages..."

    pacman -Rs $(pacman -Qq | grep '^lib32')
}

# Delete orphans packages
delete_old_packages() {
    log_message "Cleaning of excess packages..."

    set +e

    # clear pacman cache
    pacman -Scc --noconfirm
    if [ $? -ne 0 ]; then
        log_warning "Failed to clear the packet cache, but continue execution"
    fi

    ORPHANS=$(pacman -Qtdq)
    if [ -n "$ORPHANS" ]; then
        pacman -Rscn $ORPHANS --noconfirm
        if [ $? -ne 0 ]; then
            log_warning "It was not possible to delete some unnecessary packages, but we continue to execute"
        fi
    else
        log_message "No unnecessary packages were found."
    fi

    set -e
}

# Configure initramfs
upd_init() {
    log_message "Updating initramfs..."

    mkinitcpio -P
}

main() {
    log_message "Delete orphans packages (Part 5)..."

    delete_old_packages
    delete_lib32
    upd_init

    log_success "===== END OF THE 5TH PART ====="
    log_warning "Installation and optimization are complete. It is recommended to reboot the system!"
}

main
