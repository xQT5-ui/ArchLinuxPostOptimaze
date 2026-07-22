
#!/bin/bash

# =====================================================
# Post Optimiztion for Arch Linux
# =====================================================
#
set -e

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

# Check NO superuser
if [[ $EUID -eq 0 ]]; then
    log_error "This script should NOT be run with superuser rights"
    echo "Use: $0 without sudo"
    exit 1
fi

# Configure right for executing
add_right_running() {
    log_message "We grant the rights to run scripts..."

    CURRENT_DIR=$(pwd)

    if [ -d "./child" ]; then
        for script in ./child/*.sh; do
            if [ -f "$script" ]; then
                chmod +x "$script"
            fi
        done
    else
        log_error "The directory './child' not found"
        cd "$CURRENT_DIR"
        return 1
    fi

    cd "$CURRENT_DIR" || {
        log_error "Couldn't return to the original directory"
        return 1
    }

    log_success "Scripts has right for running"
}

# Create backups
create_backups() {
    log_message "Creating backups..."

    mkdir -p ./backups/security

    ROOT_BACKUPS=(
        "/etc/pacman.conf"
        "/etc/mkinitcpio.conf"
        "/etc/environment"
        "/etc/fstab"
    )

    for file in "${ROOT_BACKUPS[@]}"; do
        filename=$(basename "$file")

        if [ -f "./backups/$filename" ]; then
            log_warning "The '$filename' file already exists in the backups folder, skip it"
        else
            cp "$file" ./backups/
        fi
    done

    if [ -f "./backups/security/limits.conf" ]; then
        log_warning "The 'limits.conf' file already exists in the backups/security folder, skip it"
    else
        cp /etc/security/limits.conf ./backups/security/
    fi

    log_success "Backups have been created"
}

main() {
    {
        echo "=== Log strated at $(date) ==="
        log_message "The beginning of the installation of pre-necessary actions..."

        add_right_running
        create_backups

        log_message "Work begins on post-optimization of the system..."
        log_warning "PLEASE DO NOT LEAVE BECAUSE YOU WILL NEED TO ENTER THE SUDO PASSWORD AT DIFFERENT POINTS IN TIME!"

        sudo ./child/keyring_p0.sh && \
        sudo ./child/main_p1.sh && \
        ./child/yay_p2.sh && \
        sudo ./child/sys_optimize_p3.sh && \
        ./child/user_optimize_p4.sh && \
        sudo ./child/end.sh
    } | tee -a ./jobs.log 2>&1
}

main
