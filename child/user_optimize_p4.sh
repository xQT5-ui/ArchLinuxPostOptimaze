#!/bin/bash

# =====================================================
# Post Optimiztion for Arch Linux. Part 4
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

# Configure Pipewire
configure_pipewire() {
    log_message "Setting up and enabling Pipewire..."

    #systemctl --user enable pipewire pipewire-pulse wireplumber

    mkdir -p $HOME/.config/pipewire/pipewire.conf.d $HOME/.config/pipewire/pipewire-pulse.conf.d $HOME/.config/pipewire/client.conf.d

    cp -f ./child/files/pipewire/10-sound.conf $HOME/.config/pipewire/pipewire.conf.d/10-sound.conf
    cp -f /usr/share/pipewire/client.conf.avail/20-upmix.conf $HOME/.config/pipewire/pipewire-pulse.conf.d/20-upmix.conf
    cp -f /usr/share/pipewire/client.conf.avail/20-upmix.conf $HOME/.config/pipewire/client.conf.d/20-upmix.conf
}

# Configure GNOME services
optimize_gnome_services() {
    log_message "GNOME optimization..."

    systemctl --user mask org.gnome.SettingsDaemon.Wacom.service org.gnome.SettingsDaemon.Smartcard.service
}

# Configure ZSH
configure_zsh() {
    log_message "ZSH configuration..."

    cp -f ./child/files/zsh/zsh_history $HOME/.zsh_history
    cp -f ./child/files/zsh/zshrc $HOME/.zshrc
    cp -f ./child/files/zsh/p10k.zsh $HOME/.p10k.zsh

    chown $USER:$USER $HOME/.zshrc $HOME/.zsh_history $HOME/.p10k.zsh
}

# Configure Papirus icons theme
configure_papirus_folder_colors() {
    log_message "Set Papirus folder colors..."

     if command -v papirus-folders > /dev/null 2>&1; then
        papirus-folders -C cyan --theme Papirus-Dark
    else
        log_warning "WARNING: papirus-folders not found in PATH. Skipping configuration."
    fi
}

# Configure Fastfetch
configure_fastfetch() {
    log_message "Set Fastfetch output format..."

    cp -f ./child/files/user/fastfetch/config.jsonc $HOME/.config/fastfetch/config.jsonc
}

# Configure LM Studio
configure_lmstudio() {
    log_message "Transfer LM Studio data..."

    mkdir -p $HOME/.lmstudio

    cp -rf ./child/files/user/lmstudio/config-presets $HOME/.lmstudio/
    cp -rf ./child/files/user/lmstudio/conversations $HOME/.lmstudio/
}

# Configure Zen
configure_zen() {
    log_message "Transfer Zen data..."

    mkdir -p $HOME/.zen

    cp -r ./child/files/user/zen/* $HOME/.zen/
}

# Configure Flatpak datas
configure_flatpak() {
    log_message "Transfer Flatpak data..."

    mkdir -p $HOME/.local/share/flatpak/overrides

    cp -r ./child/files/user/flatpak/overrides/* $HOME/.local/share/flatpak/overrides/
}

# Configure Zed data
configure_zed() {
    log_message "Transfer Zed data..."

    mkdir -p $HOME/.config/zed

    cp -f ./child/files/user/zed/settings.json $HOME/.config/zed/settings.json
}

# Configure MangoHud
configure_mangohud() {
    log_message "Transfer MangoHud data..."

    mkdir -p $HOME/.config/MangoHud

    cp -f ./child/files/user/MangoHud/MangoHud.conf $HOME/.config/MangoHud/MangoHud.conf
}

# Configure EasyEffects
configure_easyeffects() {
    log_message "Transfer EasyEffects data..."

    mkdir -p $HOME/.var/app/com.github.wwmm.easyeffects/data

    cp -r ./child/files/user/easyeffects/* $HOME/.var/app/com.github.wwmm.easyeffects/data/
}

# Configure GNOME extentions
configure_gnome_exts() {
    log_message "Transfer GNOME extentions data..."

    mkdir -p $HOME/.local/share/gnome-shell/extensions

    cp -r ./child/files/user/gnomeexts/extensions/* $HOME/.local/share/gnome-shell/extensions/
    cp -f ./child/files/user/gnomeexts/dconf/user $HOME/.config/dconf/user
    dconf load /org/gnome/shell/extensions/ < ./child/files/user/gnomeexts/gnome-extensions-settings.txt
}

# Configure Git config
configure_git_data() {
    log_message "Transfer Git data..."

    mkdir -p $HOME/.ssh

    cp -f ./child/files/user/git/gitconfig $HOME/.gitconfig
    cp -r ./child/files/user/git/ssh/* $HOME/.ssh/
    
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/id_ed25519
    chmod 644 ~/.ssh/id_ed25519.pub

    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
}

main() {
    log_message "User settings optimize (Part 4)..."

    configure_pipewire
    optimize_gnome_services
    configure_zsh
    #configure_papirus_folder_colors
    configure_fastfetch
    configure_lmstudio
    configure_zen
    configure_flatpak
    configure_zed
    configure_mangohud
    configure_easyeffects
    configure_gnome_exts
    configure_git_data

    log_success "All operations have been completed successfully!"
    log_message "===== END OF THE 4TH PART ====="
}

main
