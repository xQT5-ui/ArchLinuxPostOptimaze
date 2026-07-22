#!/bin/bash

# =====================================================
# Post Optimiztion for Arch Linux. Part 2
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

# Check NO superuser
if [[ $EUID -eq 0 ]]; then
    log_error "This script should NOT be run with superuser rights"
    echo "Use: $0 without sudo"
    exit 1
fi

# Install yay
install_yay() {
    log_message "Installing yay..."

    cd $HOME
    if [ -d $HOME"/yay" ]; then
        rm -rf $HOME/yay
    fi
    git clone https://aur.archlinux.org/yay.git
    cd $HOME/yay
    makepkg -si --noconfirm
    cd $HOME
    rm -rf $HOME/yay
}

# Configure yay
setup_yay() {
    if command -v yay &> /dev/null; then
        log_message "yay is already installed"
    else
        log_message "yay is not installed. Starting the installation..."
        install_yay
    fi

    if command -v yay &> /dev/null; then
        if ! grep -q 'export PATH="$PATH:~/.local/bin"' ~/.bashrc; then
            echo 'export PATH="$PATH:~/.local/bin"' >> ~/.bashrc
            log_message "PATH updated in ~/.bashrc"
        fi
    else
        log_error "Couldn't install yay. Please check the errors above"
        exit 1
    fi
}

# Repeat installs
install_package() {
    local package=$1
    local max_attempts=3
    local attempt=1

    log_message "Installing package: $package"

    while [ $attempt -le $max_attempts ]; do
        if yay -S --noconfirm "$package"; then
            log_success "The '$package' package has been successfully installed"
            return 0
        else
            log_error "Attempt $attempt of $max_attempts failed. Repeat after 5 seconds..."
            sleep 5
            attempt=$((attempt + 1))
        fi
    done

    log_error "Failed to install the '$package' after $max_attempts attempts"
    return 1
}

# Install AUR packages
install_aur_packages() {
    log_message "Installing packages from AUR..."

    yay -Sy

    local packages=(
        "zsh-theme-powerlevel10k-git"
        "zsh-fast-syntax-highlighting"
        "bibata-cursor-theme-bin"
        "adw-gtk-theme"
        #"papirus-folders" # Ошибка с верификацией ключа
        #"ventoy-bin"
        "plex-media-server"
        "nautilus-admin-gtk4"
        #"nautilus-open-any-terminal"
        "v2raya"
        #"ttf-ms-fonts"
        #"mkinitcpio-firmware"
        #"cachyos-ananicy-rules-git"
        "xpadneo-dkms" # Для современной поддержки контроллеров
        "lmstudio-bin"
    )

    local failed_packages=()
    for package in "${packages[@]}"; do
        if ! install_package "$package"; then
            failed_packages+=("$package")
        fi
    done

    if [ ${#failed_packages[@]} -gt 0 ]; then
        log_error "The following packages could not be installed:"
        for package in "${failed_packages[@]}"; do
            echo "  - $package"
        done
    fi
}

# Configure makepkg.conf
configure_makepkg() {
    log_message "Setting up makepkg.conf..."

    cp -f ./child/files/makepkg/makepkg.conf $HOME/.makepkg.conf
}

# Configure user folders
create_directories() {
    log_message "Create additional folders..."

    mkdir -p $HOME/.themes $HOME/.icons $HOME"/Загрузки/Torrents" $HOME/.config/fastfetch

    if sudo mkdir -p /media/movies /media/tvshows; then
        ln -sf /media/movies $HOME"/Загрузки/Torrents"
        ln -sf /media/tvshows $HOME"/Загрузки/Torrents"
    else
        log_error "Media directories could not be created. Sudo rights are required"
    fi
}

# Configure usermod
configure_user_permissions() {
    log_message "Setting up user permissions..."

    if ! sudo usermod -a -G video,audio $USER; then
        log_error "Couldn't add user to groups. Sudo rights are required"
    fi

    if ! sudo gpasswd -a $USER plex && sudo gpasswd -a $USER power; then
        log_error "Couldn't add user to plex and power groups. Sudo rights are required"
    fi
}

main() {
    log_message "Install AUR-packages (Part 2)..."

    configure_makepkg
    setup_yay
    install_aur_packages
    create_directories
    configure_user_permissions

    log_success "All operations have been completed successfully!"
    log_message "===== END OF THE 2ND PART ====="
}

main
