#!/bin/bash

# Turn on strong mode for bash
set -euo pipefail

# Colors for output messages
BLUE="\e[1;34m"
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
RESET="\e[0m"

log_message() {
    echo -e "${BLUE}[INFO] $1${RESET}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${RESET}" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $1${RESET}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1${RESET}"
}

configure_transfer_data() {
    # Pipewire
    if pacman -Q pipewire > /dev/null 2>&1; then
        cp -f $HOME/.config/pipewire/pipewire.conf.d/10-sound.conf ./child/files/pipewire/10-sound.conf
    fi

    # ZSH
    if pacman -Q zsh > /dev/null 2>&1; then
        cp -f $HOME/.zsh_history ./child/files/zsh/zsh_history
        cp -f $HOME/.zshrc ./child/files/zsh/zshrc
        cp -f $HOME/.p10k.zsh ./child/files/zsh/p10k.zsh
    fi

    # Fastfetch
    if pacman -Q fastfetch > /dev/null 2>&1; then
        mkdir -p ./child/files/user/fastfetch
        cp -f $HOME/.config/fastfetch/config.jsonc ./child/files/user/fastfetch/config.jsonc
    fi

    # LM Studio
    if yay -Q lmstudio-bin > /dev/null 2>&1; then
        mkdir -p ./child/files/user/lmstudio/config-presets ./child/files/user/lmstudio/conversations/
        cp -rf $HOME/.lmstudio/config-presets/* ./child/files/user/lmstudio/config-presets/
        cp -rf $HOME/.lmstudio/conversations/* ./child/files/user/lmstudio/conversations/
    fi

    # Zen
    if flatpak list --app | grep -iq "Zen" > /dev/null 2>&1; then
        mkdir -p ./child/files/user/zen
        cp -r $HOME/.zen/* ./child/files/user/zen/
    fi

    # Flatpak
    if pacman -Q flatpak > /dev/null 2>&1; then
        mkdir -p ./child/files/user/flatpak/overrides
        cp -r $HOME/.local/share/flatpak/overrides/* ./child/files/user/flatpak/overrides/
    fi

    # Zed
    if pacman -Q zed > /dev/null 2>&1; then
        mkdir -p ./child/files/user/zed
        cp -f $HOME/.config/zed/settings.json ./child/files/user/zed/settings.json
    fi

    # MangoHud
    if flatpak list --app | grep -iq "MangoJuice" > /dev/null 2>&1; then
        mkdir -p ./child/files/user/MangoHud
        cp -f $HOME/.config/MangoHud/MangoHud.conf ./child/files/user/MangoHud/MangoHud.conf
    fi

    # EasyEffects
    if flatpak list --app | grep -iq "EasyEffects" > /dev/null 2>&1; then
        mkdir -p ./child/files/user/easyeffects
        cp -r $HOME/.var/app/com.github.wwmm.easyeffects/data/* ./child/files/user/easyeffects/
    fi

    # GNOME Exts
    if pacman -Q gnome-shell > /dev/null 2>&1; then
        mkdir -p ./child/files/user/gnomeexts/dconf ./child/files/user/gnomeexts/extensions
        cp -r $HOME/.local/share/gnome-shell/extensions/* ./child/files/user/gnomeexts/extensions/
        cp -f $HOME/.config/dconf/user ./child/files/user/gnomeexts/dconf/user
        dconf dump /org/gnome/shell/extensions/ > ./child/files/user/gnomeexts/gnome-extensions-settings.txt
    fi

    # Git
    if pacman -Q git > /dev/null 2>&1; then
        mkdir -p ./child/files/user/git/ssh
        cp -f $HOME/.gitconfig ./child/files/user/git/gitconfig
        cp -r $HOME/.ssh/* ./child/files/user/git/ssh/
    fi

    # MangoWM
    if pacman -Q mangowm > /dev/null 2>&1; then
        mkdir -p ./child/files/user/mango
        cp -r $HOME/.config/mango/* ./child/files/user/mango/
    fi

    # Noctalia
    if pacman -Q noctalia > /dev/null 2>&1; then
        mkdir -p ./child/files/user/noctalia ./child/files/user/noctalia/greetd ./child/files/user/noctalia/greetd/noctalia-greeter
        cp -f $HOME/.config/noctalia/config.toml ./child/files/user/noctalia/config.toml
        sudo cp -f /var/lib/noctalia-greeter/greeter.toml ./child/files/user/noctalia/greetd/noctalia-greeter/greeter.toml
    fi
}

main() {
    log_message "Collect all users data..."

    configure_transfer_data

    log_success "All data have been collected!"
}

main
