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

configure_pipewire() {
    if yay -Q pipewire > /dev/null 2>&1; then
        log_message "Transfer Pipewire data..."

        #systemctl --user enable pipewire pipewire-pulse wireplumber

        mkdir -p $HOME/.config/pipewire/pipewire.conf.d $HOME/.config/pipewire/pipewire-pulse.conf.d $HOME/.config/pipewire/client.conf.d

        cp -f ./child/files/pipewire/10-sound.conf $HOME/.config/pipewire/pipewire.conf.d/10-sound.conf
        cp -f /usr/share/pipewire/client.conf.avail/20-upmix.conf $HOME/.config/pipewire/pipewire-pulse.conf.d/20-upmix.conf
        cp -f /usr/share/pipewire/client.conf.avail/20-upmix.conf $HOME/.config/pipewire/client.conf.d/20-upmix.conf
    fi
}

configure_gnome_services() {
    if [ "$GNOME" = "true" ]; then
        log_message "GNOME optimization..."

        systemctl --user mask org.gnome.SettingsDaemon.Wacom.service org.gnome.SettingsDaemon.Smartcard.service
    fi
}

configure_zsh_data() {
    if yay -Q zsh > /dev/null 2>&1; then
        log_message "Transfer ZSH data..."

        cp -f ./child/files/zsh/zsh_history $HOME/.zsh_history
        cp -f ./child/files/zsh/zshrc $HOME/.zshrc
        cp -f ./child/files/zsh/p10k.zsh $HOME/.p10k.zsh

        chown $USER:$USER $HOME/.zshrc $HOME/.zsh_history $HOME/.p10k.zsh
    fi
}

configure_papirus_folder_colors() {
    if command -v papirus-folders > /dev/null 2>&1; then
        log_message "Set Papirus folder colors..."

        papirus-folders -C cyan --theme Papirus-Dark
    fi
}

configure_fastfetch() {
    if yay -Q fastfetch > /dev/null 2>&1; then
        log_message "Transfer Fastfetch data..."

        mkdir -p $HOME/.config/fastfetch

        cp -f ./child/files/user/fastfetch/config.jsonc $HOME/.config/fastfetch/config.jsonc
    fi
}

configure_lmstudio() {
    if yay -Q lmstudio-bin > /dev/null 2>&1; then
        log_message "Transfer LM Studio data..."

        mkdir -p $HOME/.lmstudio

        cp -rf ./child/files/user/lmstudio/config-presets $HOME/.lmstudio/
        cp -rf ./child/files/user/lmstudio/conversations $HOME/.lmstudio/
    fi
}

configure_zen() {
    if flatpak list --app | grep -iq "zen" > /dev/null 2>&1; then
        log_message "Transfer Zen data..."

        mkdir -p $HOME/.zen

        cp -r ./child/files/user/zen/* $HOME/.zen/
    fi
}

configure_flatpak() {
    if flatpak list --app | grep -iq "flatseal" > /dev/null 2>&1; then
        log_message "Transfer Flatpak data..."

        mkdir -p $HOME/.local/share/flatpak/overrides

        cp -r ./child/files/user/flatpak/overrides/* $HOME/.local/share/flatpak/overrides/
    fi
}

configure_zed() {
    if yay -Q zed > /dev/null 2>&1; then
        log_message "Transfer Zed data..."

        mkdir -p $HOME/.config/zed

        cp -f ./child/files/user/zed/settings.json $HOME/.config/zed/settings.json
    fi
}

configure_mangohud() {
    if flatpak list --runtime | grep -iq "mangohud" > /dev/null 2>&1; then
        log_message "Transfer MangoHud data..."

        mkdir -p $HOME/.config/MangoHud

        cp -f ./child/files/user/MangoHud/MangoHud.conf $HOME/.config/MangoHud/MangoHud.conf
    fi
}

configure_easyeffects() {
    if flatpak list --app | grep -iq "easyeffects" > /dev/null 2>&1; then
        log_message "Transfer EasyEffects data..."

        mkdir -p $HOME/.var/app/com.github.wwmm.easyeffects/data

        cp -r ./child/files/user/easyeffects/* $HOME/.var/app/com.github.wwmm.easyeffects/data/
    fi
}

configure_gnome_exts() {
    if [ "$GNOME" = "true" ]; then
        log_message "Transfer GNOME extentions data..."

        mkdir -p $HOME/.local/share/gnome-shell/extensions

        cp -r ./child/files/user/gnomeexts/extensions/* $HOME/.local/share/gnome-shell/extensions/
        cp -f ./child/files/user/gnomeexts/dconf/user $HOME/.config/dconf/user

        dconf load /org/gnome/shell/extensions/ < ./child/files/user/gnomeexts/gnome-extensions-settings.txt
    fi
}

configure_git_data() {
    if yay -Q git > /dev/null 2>&1; then
        if ! [ -d "$HOME/.ssh" ]; then
            log_message "Transfer Git data..."
            mkdir -p $HOME/.ssh

            cp -f ./child/files/user/git/gitconfig $HOME/.gitconfig
            cp -r ./child/files/user/git/ssh/* $HOME/.ssh/

            chmod 700 $HOME/.ssh
            chmod 600 $HOME/.ssh/id_ed25519
            chmod 644 $HOME/.ssh/id_ed25519.pub

            eval "$(ssh-agent -s)"
            ssh-add $HOME/.ssh/id_ed25519
        fi
    fi
}

configure_happ() {
    if yay -Q happ-desktop-bin > /dev/null 2>&1; then
        log_message "Transfer Happ data..."

        mkdir -p $HOME/.config/Happ

        cp -r ./child/files/user/happ $HOME/.config/Happ
    fi
}

configure_mangowm() {
    if [ "$MANGOWM" = "true" ]; then
        log_message "Transfer MangoWM data..."

        mkdir -p $HOME/.config/mango

        cp -r ./child/files/user/mango/* $HOME/.config/mango
    fi
}

configure_wmshell() {
    if [ "$MANGOWM" = "true" ]; then
        log_message "Transfer WM Shell data..."

        if yay -Q noctalia > /dev/null 2>&1; then
            mkdir -p $HOME/.config/noctalia

            cp -f ./child/files/user/noctalia/config.toml $HOME/.config/noctalia/config.toml
        fi

        if yay -Q noctalia-greeter > /dev/null 2>&1; then
            sudo cp -f ./child/files/user/noctalia/greetd/config.toml /etc/greetd/config.toml
            sudo cp -f ./child/files/user/noctalia/greetd/noctalia-greeter/greeter.toml /var/lib/noctalia-greeter/greeter.toml
        fi

        # from Niri desktop installation
        yay -Rns fuzzel alacritty mako niri swaybg swayidle swaylock waybar lightdm-gtk-greeter xdg-desktop-portal-gnome --noconfirm
    fi
}

main() {
    log_message "User settings optimize (Part 4)..."

    configure_pipewire
    configure_gnome_services
    configure_zsh_data
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
    #configure_happ
    configure_mangowm
    configure_wmshell

    log_success "All operations have been completed successfully!"
    log_message "===== END OF THE 4TH PART ====="
}

main
