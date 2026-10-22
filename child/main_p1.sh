#!/bin/bash

# Turn on strong mode for bash
#exit by any error
set -e
#only static variable
set -u

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

# Check superuser
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run with superuser rights"
    echo "Use: sudo $0"
    exit 1
fi

configure_pacman() {
    log_message "Configuring the pacman.conf configuration..."

    cp -f ./child/files/etc/pacman/pacman.conf /etc/pacman.conf
}

# Wrapper for installing pacman packages
install_pacman_package() {
    local package=$1
    local max_attempts=3
    local attempt=1

    log_message "Instaling pacman package: $package"

    while [ $attempt -le $max_attempts ]; do
        if pacman -S --noconfirm "$package"; then
            log_success "The pacman '$package' package has been successfully installed"
            return 0
        else
            log_error "The $attempt from $max_attempts to install the pacman '$package' failed. Repeat after 5 seconds..."
            sleep 5
            attempt=$((attempt + 1))
        fi
    done

    log_error "Failed to install the pacman '$package' after $max_attempts attempts"
    return 1
}

install_base_apps() {
    log_message "Installing native apps..."

    pacman -Syu --noconfirm

    local pacmanPackages=(
        "git"
        "lrzip"
        "unrar"
        "unace"
        "p7zip"
        "zsh"
        "zsh-autosuggestions"
        "zsh-completions"
        "zsh-history-substring-search"
        "xorg-xrandr"
        "go"
        "gdu"
        "duf"
        #"wireguard-tools"
        "power-profiles-daemon"
        "alsa-utils"
        "pacman-contrib"
        "inxi"
        "exfat-utils"
        "file-roller"
        "papirus-icon-theme"
        #"irqbalance"
        #"ananicy-cpp"
        "fwupd"
        "earlyoom"
        "fastfetch"
        "scx-scheds"
        "scx-tools"
        "fakeroot"
        "make"
        "gcc"
        "debugedit"
        "intel-ucode"
        "intel-media-driver"
        "zed"
    )

    if $GNOME; then
        pacmanPackages+=("gnome-shell-extensions")
    else
        pacmanPackages+=(
            "mangowm"
            "noctalia"
            "greetd"
            "noctalia-greeter"
        )
    fi

    local failed_pacmanPackages=()
    for package in "${pacmanPackages[@]}"; do
        if ! install_pacman_package "$package"; then
            failed_pacmanPackages+=("$package")
        fi
    done

    if [ ${#failed_pacmanPackages[@]} -gt 0 ]; then
        log_error "The following pacman packages could not be installed:"
        for package in "${failed_pacmanPackages[@]}"; do
            echo "  - $package"
        done
    else
        log_success "All packages from Pacman have been successfully installed"
    fi

    # update font cache
    fc-cache -fv

    if $NVIDIA; then
        local pacmanNVIDIA=(
            "nvidia-settings"
            "opencl-nvidia"
            "libvdpau-va-gl"
            "libxnvctrl"
        )

        local failed_pacmanNVIDIA=()
        for package in "${pacmanNVIDIA[@]}"; do
            if ! install_pacman_package "$package"; then
            failed_pacmanNVIDIA+=("$package")
            fi
        done

        if [ ${#failed_pacmanNVIDIA[@]} -gt 0 ]; then
            log_error "The following pacman NVIDIA packages could not be installed:"
            for package in "${failed_pacmanNVIDIA[@]}"; do
            echo "  - $package"
            done
        else
            log_success "All packages from Pacman NVIDIA have been successfully installed"
        fi
    fi
}

delete_gnome_applications() {
    if $GNOME; then
        log_message "Optimize GNOME by removing unnecessary packages..."

        pacman -Rnsc --noconfirm gnome-connections gnome-software gnome-music gnome-maps gnome-contacts gnome-system-monitor gnome-tour gnome-weather loupe epiphany yelp decibels vim malcontent evince sushi baobab gvfs-onedrive gnome-backgrounds showtime papers snapshot gnome-calculator
        pacman -S --noconfirm flatpak
    fi
}

# Wrapper for installing Flatpak packages
install_flatpak_package() {
    local package=$1
    local max_attempts=3
    local attempt=1

    log_message "Instaling flatpak package: $package"

    while [ $attempt -le $max_attempts ]; do
        if flatpak install --noninteractive "$package"; then
            log_success "The flatpak '$package' package has been successfully installed"
            return 0
        else
            log_error "The $attempt from $max_attempts to install the flatpak '$package' failed. Repeat after 5 seconds..."
            sleep 5
            attempt=$((attempt + 1))
        fi
    done

    log_error "Failed to install the flatpak '$package' after $max_attempts attempts"
    return 1
}

install_flatpak_apps() {
    log_message "Installing Flatpak apps..."

    local flatpakPackages=(
        "com.bitwig.BitwigStudio"
        "io.github.milkshiift.GoofCord"
        "com.andr2i.scrolex"
        "com.github.finefindus.eyedropper"
        "io.bassi.Amberol"
        "com.github.tchx84.Flatseal"
        "com.mattjakeman.ExtensionManager"
        "de.haeckerfelix.Fragments"
        "com.usebottles.bottles"
        "com.vysp3r.ProtonPlus"
        "io.github.diegopvlk.Cine"
        "io.github.flattool.Warehouse"
        "io.github.jliljebl.Flowblade"
        "io.github.seadve.Mousai"
        "org.gnome.Mines"
        "org.gnome.Quadrapassel"
        "app.drey.EarTag"
        "org.nickvision.tubeconverter"
        "org.onlyoffice.desktopeditors"
        "org.telegram.desktop"
        "org.torproject.torbrowser-launcher"
        "org.gtk.Gtk3theme.adw-gtk3-dark"
        "com.obsproject.Studio"
        "io.missioncenter.MissionCenter"
        "com.github.PintaProject.Pinta"
        "org.gnome.Calculator"
        "org.gnome.Loupe"
        "com.github.ryonakano.reco"
        "org.soundconverter.SoundConverter"
        "org.pipewire.Helvum"
        "app.zen_browser.zen"
        "com.jgraph.drawio.desktop"
        "com.github.wwmm.easyeffects"
        "io.github.radiolamp.mangojuice"
        "com.valvesoftware.Steam"
        "org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/25.08"
        "app.devsuite.Ptyxis"
        #"org.nickvision.cavalier" # Для визуализации исходящего звука
        "it.mijorus.gearlever" # Для работы с AppImage
        "de.wwwtech.gitte"
        "io.github.anil_e.Codd"
        "io.github.dzheremi2.lrcmake-gtk"
        "dev.bragefuglseth.Keypunch"
        "io.github.diegopvlk.Tomatillo"
        "io.gitlab.adhami3310.Impression"
        "org.gnome.Snapshot"
        "com.rafaelmardojai.Blanket"
    )

    local failed_flatpakPackages=()
    for package in "${flatpakPackages[@]}"; do
        if ! install_flatpak_package "$package"; then
            failed_flatpakPackages+=("$package")
        fi
    done

    if [ ${#failed_flatpakPackages[@]} -gt 0 ]; then
        log_error "The following flatpak packages could not be installed:"
        for package in "${failed_flatpakPackages[@]}"; do
            echo "  - $package"
        done
    fi

    flatpak repair
    flatpak update -y
    flatpak remove --unused -y
}

main() {
    log_message "Install main packages (Part 1)..."

    configure_pacman
    install_base_apps
    install_flatpak_apps
    delete_gnome_applications

    log_success "All operations have been completed successfully!"
    log_message "===== END OF THE 1ST PART ====="
}

main
