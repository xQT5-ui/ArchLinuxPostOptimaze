#!/bin/bash

# ==================================
# Copy user data from system
# ==================================

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

configure_transfer_data() {
    # Pipewire
    cp -f $HOME/.config/pipewire/pipewire.conf.d/10-sound.conf ./child/files/pipewire/10-sound.conf

    # ZSH
    cp -f $HOME/.zsh_history ./child/files/zsh/zsh_history
    cp -f $HOME/.zshrc ./child/files/zsh/zshrc
    cp -f $HOME/.p10k.zsh ./child/files/zsh/p10k.zsh

    # Fastfetch
    mkdir -p ./child/files/user/fastfetch
    cp -f $HOME/.config/fastfetch/config.jsonc ./child/files/user/fastfetch/config.jsonc

    # LM Studio
    mkdir -p ./child/files/user/lmstudio/config-presets ./child/files/user/lmstudio/conversations/
    cp -rf $HOME/.lmstudio/config-presets/* ./child/files/user/lmstudio/config-presets/
    cp -rf $HOME/.lmstudio/conversations/* ./child/files/user/lmstudio/conversations/

    # Zen
    mkdir -p ./child/files/user/zen
    cp -r $HOME/.zen/* ./child/files/user/zen/

    # Flatpak
    mkdir -p ./child/files/user/flatpak/overrides
    cp -r $HOME/.local/share/flatpak/overrides/* ./child/files/user/flatpak/overrides/

    # Zed
    mkdir -p ./child/files/user/zed
    cp -f $HOME/.config/zed/settings.json ./child/files/user/zed/settings.json

    # MangoHud
    mkdir -p ./child/files/user/MangoHud
    cp -f $HOME/.config/MangoHud/MangoHud.conf ./child/files/user/MangoHud/MangoHud.conf

    # EasyEffects
    mkdir -p ./child/files/user/easyeffects
    cp -r $HOME/.var/app/com.github.wwmm.easyeffects/data/* ./child/files/user/easyeffects/

    # GNOME Exts
    mkdir -p ./child/files/user/gnomeexts/dconf ./child/files/user/gnomeexts/extensions
    cp -r $HOME/.local/share/gnome-shell/extensions/* ./child/files/user/gnomeexts/extensions/
    cp -f $HOME/.config/dconf/user ./child/files/user/gnomeexts/dconf/user
    dconf dump /org/gnome/shell/extensions/ > ./child/files/user/gnomeexts/gnome-extensions-settings.txt

    # Git
    mkdir -p ./child/files/user/git/ssh
    cp -f $HOME/.gitconfig ./child/files/user/git/gitconfig
    cp -r $HOME/.ssh/* ./child/files/user/git/ssh/
}

main() {
    log_message "Collect all users data..."

    configure_transfer_data

    log_success "All data have been collected!"
}

main
