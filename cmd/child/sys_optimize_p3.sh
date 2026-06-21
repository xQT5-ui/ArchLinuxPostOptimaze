#!/bin/bash

# =====================================================
# Скрипт для оптимизации и настройки Arch Linux. Часть 3
# =====================================================

# Включаем строгий режим для bash
set -e  # Скрипт завершится при любой ошибке
set -u  # Использование неопределенных переменных вызовет ошибку

# Цвета для вывода сообщений
BLUE="\e[1;34m"
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
RESET="\e[0m"

# Функция для вывода информационных сообщений
log_message() {
    echo -e "${BLUE}[INFO] $1${RESET}"
}

# Функция для вывода сообщений об ошибках
log_error() {
    echo -e "${RED}[ERROR] $1${RESET}" >&2
}

# Функция для вывода сообщений об успешном выполнении
log_success() {
    echo -e "${GREEN}[SUCCESS] $1${RESET}"
}

# Функция для вывода предупреждений
log_warning() {
    echo -e "${YELLOW}[WARNING] $1${RESET}"
}

# Проверка наличия прав суперпользователя
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run with superuser rights"
    echo "Use: sudo $0"
    exit 1
fi

# Функция для проверки наличия видеокарты NVIDIA
has_nvidia() {
    log_message "Checking for an NVIDIA graphics card..."

    # Способ 1: Проверка через lspci
    if lspci | grep -i nvidia > /dev/null; then
        log_success "NVIDIA graphics card detected"
        return 0  # В bash 0 означает "истина" (успех)
    fi

    # Способ 2: Проверка через наличие модуля ядра
    if lsmod | grep -i nvidia > /dev/null; then
        log_success "NVIDIA driver detected"
        return 0
    fi

    log_message "NVIDIA graphics card not detected"
    return 1  # В bash 1 (и любое ненулевое значение) означает "ложь" (неудача)
}

# Глобальная переменная для хранения результата проверки
if has_nvidia; then
    NVIDIA_PRESENT=true
else
    NVIDIA_PRESENT=false
fi

# Функция для настройки initramfs
configure_initramfs() {
    log_message "Configuring initramfs images..."

    # Ускорение загрузки системы c помощью systemd
    cp -f ./child/files/etc/mkinitcpio.conf /etc/mkinitcpio.conf
    if [[ -f /etc/mkinitcpio.conf ]]; then
        mkinitcpio -P
        log_success "Initramfs rebuilt successfully"
    fi
}

# Функция для настройки загрузчика
configure_bootloader() {
    log_message "Configuring the boot loader..."

    cp -f ./child/files/boot/loader.conf /boot/loader/loader.conf
    sed -i 's/^options.*/options rw quiet splash/' /boot/loader/entries/arch-linux.conf
}

# Функция для настройки параметров ядра
configure_sysctl() {
    log_message "Configuring kernel parameters via sysctl..."

    cp -f ./child/files/etc/sysctl.d/99-sysctl.conf /etc/sysctl.d/99-sysctl.conf
}

# Функция для настройки переменных окружения (NVIDIA)
configure_wayland() {
    log_message "Setting up environment variables..."

    # Дополнение /etc/environment
    if $NVIDIA_PRESENT; then
        cp -f ./child/files/etc/environment /etc/environment
   fi
}

# Функция для настройки Plex Media Server
configure_plex() {
    log_message "The Plex Media Server add-on..."

    # Устанавливаем владельца над папкой
    chown -R plex:plex /media
    # Добавляем права самой родительской папке
    chmod -R 775 /media

    # Настраиваем службу
    systemctl enable plexmediaserver.service
    systemctl start plexmediaserver.service
}

# Функция для установки и настройки системных служб
configure_system_services() {
    log_message "Configuring system services and daemons..."

    systemctl daemon-reload
    # Настройка zram
    cp -f ./child/files/etc/systemd/zram-generator.conf /etc/systemd/zram-generator.conf

    # Настройка службы v2raya
    log_message "Creating a v2raya service configuration..."
    cat << EOF > /etc/systemd/system/v2raya.service
[Unit]
Description=Proxy v2rayA Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/v2raya
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # Включение и запуск системных служб
    # nvidia-powerd
    # systemd-zram-setup@zram0.service
    # cronie.service = only for BTRFS
    for service in bluetooth.service v2raya.service power-profiles-daemon irqbalance ananicy-cpp earlyoom paccache.timer; do
        if systemctl list-unit-files | grep -q "^${service}"; then
            systemctl enable ${service}
        else
            log_error "Service not found: ${service}"
        fi
    done
    #systemd-zram-setup@zram0.service
    systemctl start bluetooth.service v2raya.service

    # Настройка еженедельной очистки кэша pacman
    # Удаляем таймер, если он существует
    if systemctl list-timers | grep -q pacman-cleaner.timer; then
        systemctl stop pacman-cleaner.timer
        systemctl disable pacman-cleaner.timer
        rm -f /etc/systemd/system/pacman-cleaner.timer
    fi

    systemd-run --on-calendar="Sun 10:00" --unit="pacman-cleaner" /sbin/pacman -Scc
}

# Функция для настройки NVIDIA
configure_nvidia() {
    if ! $NVIDIA_PRESENT; then
        log_message "The NVIDIA graphics card is not detected. Skipping NVIDIA settings"
        return 0
    fi

    log_message "Setting up NVIDIA..."

    # Правка конфига nvidia.conf
    cp -f ./child/files/etc/modprobe.d/nvidia.conf /etc/modprobe.d/nvidia.conf
}

# Функция для замены bash на zsh
change_shell_to_zsh() {
    log_message "Replacing bash with zsh..."

    chsh -s /bin/zsh
}

# Функция для отключения планировщика для систем с NVMe SSD
disable_nvmesh_scheduler() {
    if lsblk -d -o name | grep -iq 'nvm'; then
        log_message "Disabling the NVMe SSD scheduler..."
        cat << EOF > /etc/udev/rules.d/60-ioschedulers.rules
# NVMe SSD
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
EOF
    fi
}

# Функция для корректной настройки приоритетов при работе с аудио
configure_realtime_audio() {
    log_message "Configure realtime audio priority..."

    mkdir -p /etc/security/limits.d
    cat << EOF > /etc/security/limits.d/20-rt-audio.conf
@audio - rtprio 98
EOF
}

# Функция для настройки OOM
configure_earlyoom() {
    log_message "Setting up earlyoom rules..."

    cp -f ./child/files/etc/earlyoom /etc/default/earlyoom
}

# Функция для настройки альтернативного планировщика
configure_sched() {
    log_message "Setting up alternative SCX scheduler..."

    cp -f ./child/files/etc/scx_loader.toml /etc/scx_loader.toml
    systemctl enable --now scx_loader.service
}

# Основная функция
main() {
    log_message "System optimizations (Part 3)..."

    # Вывод информации о наличии NVIDIA
    if $NVIDIA_PRESENT; then
        log_message "An NVIDIA graphics card has been detected. The appropriate settings will be applied."
    else
        log_message "No NVIDIA graphics card detected. NVIDIA settings will be skipped."
    fi

    configure_initramfs
    #configure_bootloader
    configure_sysctl
    configure_wayland
    configure_plex
    configure_system_services
    configure_nvidia
    change_shell_to_zsh
    #disable_nvmesh_scheduler
    configure_realtime_audio
    configure_earlyoom
    configure_sched

    log_success "All operations have been completed successfully!"
    log_message "===== END OF THE 3D PART ====="
}

# Запуск основной функции
main
