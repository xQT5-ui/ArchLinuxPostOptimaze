#!/bin/bash

# =====================================================
# Post Optimiztion for Arch Linux. Part 0
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

# Configure mirrors
update_mirrors() {
    log_message "Updating the list of mirrors..."

    if ! pacman -Q reflector &>/dev/null; then
        pacman -S --noconfirm reflector rsync
    fi

    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

    if [[ -f /etc/pacman.d/mirrorlist ]]; then
        LAST_UPDATE=$(stat -c %Y /etc/pacman.d/mirrorlist 2>/dev/null || echo "0")
        CURRENT_TIME=$(date +%s)
        if (( CURRENT_TIME - LAST_UPDATE < 86400 )); then
            log_success "Mirror list updated less than 24 hours ago. Skip update"
            return 0
        fi
    fi

    reflector --country Denmark,Norway,Russia,Finland,Worldwide --latest 8 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
}

# Set mirror update service
setup_mirror_update_timer() {
    log_message "Setting up automatic mirror updates..."

    if [[ ! -f /etc/systemd/system/mirror-update.service ]]; then
        mkdir -p /etc/systemd/system
        cat > /etc/systemd/system/mirror-update.service << EOF
[Unit]
Description=Update Arch Linux mirrorlist
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/reflector --country Denmark,Norway,Russia,Finland,Worldwide --latest 8 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

[Install]
WantedBy=multi-user.target
EOF

        cat > /etc/systemd/system/mirror-update.timer << EOF
[Unit]
Description=Weekly update of Arch Linux mirrorlist
Requires=mirror-update.service

[Timer]
OnCalendar=weekly
Persistent=true
RandomizedDelaySec=6h

[Install]
WantedBy=timers.target
EOF

        systemctl daemon-reload

        systemctl enable mirror-update.timer
        systemctl start mirror-update.timer

        log_message "Created mirror-update.service"
    else
        log_message "mirror-update.service already exists. Skipping creation."
    fi
}

# Configure keys
update_keys() {
    log_message "Updating Arch Linux keys..."

    if ! systemctl is-active --quiet archlinux-keyring-wkd-sync.timer 2>/dev/null; then
        log_message "Enabling built-in keyring sync timer..."
        systemctl enable --now archlinux-keyring-wkd-sync.timer
    fi

    # Turn off exits by error temporaly
    set +e

    pacman-key --refresh-keys

    set -e
}

main() {
    log_message "Update keys and mirrors of the Arch Linux system..."

    update_mirrors
    setup_mirror_update_timer
    #update_keys

    log_success "All operations have been completed successfully!"
}

main
