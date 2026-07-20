#!/bin/bash

# =====================================================
# Скрипт для обновления ключей и зеркал Arch Linux. Часть 0
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
    log_error "This script MUST be run with superuser rights"
    echo "Use: sudo $0"
    exit 1
fi

# Функция для обновления зеркал
update_mirrors() {
    log_message "Updating the list of mirrors..."

    # Установка reflector, если он не установлен
    if ! pacman -Q reflector &>/dev/null; then
        pacman -S --noconfirm reflector rsync
    fi

    # Создание резервной копии текущего списка зеркал
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    # Проверка актуальности зеркал (опционально)
    if [[ -f /etc/pacman.d/mirrorlist ]]; then
        LAST_UPDATE=$(stat -c %Y /etc/pacman.d/mirrorlist 2>/dev/null || echo "0")
        CURRENT_TIME=$(date +%s)
        if (( CURRENT_TIME - LAST_UPDATE < 86400 )); then
            log_success "Mirror list updated less than 24 hours ago. Skip update"
            return 0
        fi
    fi

    # Обновление списка зеркал
    reflector --country Denmark,Norway,Russia,Finland,Worldwide --latest 8 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
}

# Функция для настройки автоматического обновления зеркал
setup_mirror_update_timer() {
    log_message "Setting up automatic mirror updates..."

    # Создаем директорию для пользовательских сервисов, если её нет
    if [[ ! -f /etc/systemd/system/mirror-update.service ]]; then
        mkdir -p /etc/systemd/system
        # Создаем файл сервиса для обновления зеркал
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

        # Создаем файл таймера для запуска сервиса раз в неделю
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

        # Перезагружаем конфигурацию systemd
        systemctl daemon-reload

        # Включаем и запускаем таймер
        systemctl enable mirror-update.timer
        systemctl start mirror-update.timer

        log_message "Created mirror-update.service"
    else
        log_message "mirror-update.service already exists. Skipping creation."
    fi
}

# Функция для обновления ключей
update_keys() {
    log_message "Updating Arch Linux keys..."

    # Проверка наличия встроенного таймера
    if ! systemctl is-active --quiet archlinux-keyring-wkd-sync.timer 2>/dev/null; then
        log_message "Enabling built-in keyring sync timer..."
        systemctl enable --now archlinux-keyring-wkd-sync.timer
    fi

    # Временно отключаем режим завершения при ошибке
    set +e

    # Синхронизация ключей (раз в день по умолчанию)
    pacman-key --refresh-keys

    set -e
}

# Основная часть скрипта
main() {
    log_message "Update keys and mirrors of the Arch Linux system..."

    update_mirrors
    setup_mirror_update_timer
    #update_keys

    log_success "All operations have been completed successfully!"
}

# Запуск основной функции
main
