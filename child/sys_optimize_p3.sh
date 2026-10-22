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

configure_initramfs() {
    log_message "Configuring initramfs images..."

    cp -f ./child/files/etc/mkinitcpio.conf /etc/mkinitcpio.conf
}

configure_bootloader() {
    log_message "Configuring the boot loader..."

    cp -f ./child/files/boot/loader.conf /boot/loader/loader.conf
    #sed -i 's/^options.*/options rw quiet splash/' /boot/loader/entries/arch-linux.conf
}

# Configure kernel attributes
configure_sysctl() {
    log_message "Configuring kernel parameters via sysctl..."

    cp -f ./child/files/etc/sysctl.d/99-sysctl.conf /etc/sysctl.d/99-sysctl.conf
}

configure_envs() {
    if $NVIDIA; then
        log_message "Setting up environment variables..."

        cp -f ./child/files/etc/environment /etc/environment
    fi
}

configure_plex() {
    if yay -Q plex-media-server > /dev/null 2>&1; then
        log_message "The Plex Media Server add-on..."

        # set owner
        chown -R plex:plex /media
        # add rights
        chmod -R 775 /media

        systemctl enable plexmediaserver.service
        systemctl start plexmediaserver.service
    fi
}

configure_system_services() {
    log_message "Configuring system services and daemons..."

    systemctl daemon-reload

    # zram without the SWAP!
    #cp -f ./child/files/etc/systemd/zram-generator.conf /etc/systemd/zram-generator.conf

    # nvidia-powerd -> only for >= RTX 40xx
    # irqbalance ananicy-cpp -> only without scx_sched
    # systemd-oomd -> only 1 oom
    for service in bluetooth.service power-profiles-daemon earlyoom paccache.timer v2raya reflector.timer; do
        if systemctl list-unit-files | grep -q "^${service}"; then
            systemctl enable ${service}
        else
            log_error "Service not found: ${service}"
        fi
    done

    systemctl start bluetooth.service v2raya
}

configure_nvidia() {
    if $NVIDIA; then
        log_message "Setting up NVIDIA..."

        cp -f ./child/files/etc/modprobe.d/nvidia.conf /etc/modprobe.d/nvidia.conf
    fi
}

change_shell_to_zsh() {
    if yay -Q zsh > /dev/null 2>&1; then
        log_message "Replacing bash with zsh..."

        chsh -s /bin/zsh
    fi
}

configure_nvme_scheduler() {
    if lsblk -d -o name | grep -iq 'nvm'; then
        log_message "Disabling the NVMe SSD scheduler..."

        cat << EOF > /etc/udev/rules.d/60-ioschedulers.rules
# NVMe SSD
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
EOF
    fi
}

configure_realtime_audio() {
    log_message "Configure realtime audio priority..."

    mkdir -p /etc/security/limits.d
    cat << EOF > /etc/security/limits.d/20-rt-audio.conf
@audio - rtprio 98
EOF
}

configure_oom() {
    if yay -Q earlyoom > /dev/null 2>&1; then
        log_message "Setting up OOM rules..."

        cp -f ./child/files/etc/default/earlyoom /etc/default/earlyoom
    fi
}

# Configure alternative kernel scheduler
configure_sched() {
    if yay -Q scx-scheds > /dev/null 2>&1; then
        log_message "Setting up alternative SCX scheduler..."

        cp -f ./child/files/etc/scx_loader.toml /etc/scx_loader.toml
        systemctl enable --now scx_loader.service
    fi
}

configure_firewall() {
    if yay -Q firewalld > /dev/null 2>&1; then
        log_message "Setting up firewall rights..."

        # v2rayA
        firewall-cmd --permanent --zone=trusted --add-interface=tun0
        # Plex Media Server
        cp -f ./child/files/etc/firewalld/plex.xml /etc/firewalld/services/plex.xml
        firewall-cmd --add-service=plex --permanent
        # LM Studio
        firewall-cmd --permanent --add-port=1234/tcp
    fi
}

configure_ntsync() {
    if lsmod | grep -q ntsync; then
        log_warning "NTSync module is already on"
    else
        log_message "Setting up NTsync..."

        pacman -S ntsync-autoload --noconfirm
    fi
}

configure_swap() {
    if swapon --show > /dev/null/ 2>&1; then
        log_message "Setting up Swap..."

        fallocate -l 8G /swapfile
        chmod 600 /swapfile
        # for BTRFS
        #chattr +C /swapfile
        mkswap /swapfile
        swapon /swapfile
        printf "\n/swapfile none swap defaults 0 0\n" >> /etc/fstab
        echo " zswap.compressor=zstd zswap.max_pool_percent=21" >> /boot/limine.cfg
    fi
}

configure_snapper() {
    log_message "Setting up Snapper..."

    umount /.snapshots
    rm -rf /.snapshots

    snapper -c root create-config /
    chmod 750 /.snapshots

    sed -i 's/^TIMELINE_LIMIT_HOURLY.*/TIMELINE_LIMIT_HOURLY=\"0\"/' /etc/snapper/configs/root
    sed -i 's/^TIMELINE_LIMIT_DAILY.*/TIMELINE_LIMIT_DAILY=\"5\"/' /etc/snapper/configs/root
    sed -i 's/^TIMELINE_LIMIT_WEEKLY.*/TIMELINE_LIMIT_WEEKLY=\"0\"/' /etc/snapper/configs/root
    sed -i 's/^TIMELINE_LIMIT_MONTHLY.*/TIMELINE_LIMIT_MONTHLY=\"0\"/' /etc/snapper/configs/root
    sed -i 's/^TIMELINE_LIMIT_YEARLY.*/TIMELINE_LIMIT_YEARLY=\"0\"/' /etc/snapper/configs/root
}

configure_btrfs() {
    log_message "Setting up BTRFS maintenance..."

    systemctl enable --now btrfs-scrub@-.timer
    systemctl enable --now btrfs-scrub@home.timer
}

main() {
    log_message "System optimizations (Part 3)..."

    configure_initramfs
    #configure_bootloader
    configure_sysctl
    #configure_envs
    configure_plex
    configure_system_services
    configure_nvidia
    change_shell_to_zsh
    #configure_nvme_scheduler
    configure_realtime_audio
    configure_oom
    configure_sched
    configure_firewall
    configure_ntsync
    configure_swap
    configure_snapper
    configure_btrfs

    log_success "All operations have been completed successfully!"
    log_message "===== END OF THE 3D PART ====="
}

main
