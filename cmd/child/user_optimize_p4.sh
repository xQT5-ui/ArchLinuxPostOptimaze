#!/bin/bash

# =====================================================
# Скрипт для оптимизации пользовательских настроек Arch Linux. Часть 4
# Запускать после ручной перезагрузки после Часть 3!
# =====================================================

# Включаем строгий режим для bash
set -e  # Скрипт завершится при любой ошибке
set -u  # Использование неопределенных переменных вызовет ошибку

# Цвета для вывода сообщений
BLUE="\e[1;34m"
RED="\e[1;31m"
GREEN="\e[1;32m"
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

# Функция для проверки успешности выполнения команды
check_success() {
    if [ $? -ne 0 ]; then
        log_error "Error during execution: $1"
        exit 1
    fi
}

# Функция для настройки Pipewire
configure_pipewire() {
    log_message "Setting up and enabling Pipewire..."

    # Включение служб Pipewire
    systemctl --user enable --now pipewire pipewire.socket pipewire-pulse wireplumber
    check_success "enabling Pipewire"

    # Создание директорий для конфигурации
    mkdir -p ~/.config/pipewire/pipewire.conf.d ~/.config/pipewire/pipewire-pulse.conf.d ~/.config/pipewire/client.conf.d
    check_success "creating directories for Pipewire configuration"

    # Создание конфигурационного файла для звука
    cp -f ./files/pipewire/10-sound.conf ~/.config/pipewire/pipewire.conf.d
    check_success "creating a configuration file for audio"

    # Копирование дополнительных конфигурационных файлов
    cp /usr/share/pipewire/client.conf.avail/20-upmix.conf ~/.config/pipewire/pipewire-pulse.conf.d
    check_success "copying the upmix configuration for pipewire-pulse"

    cp /usr/share/pipewire/client.conf.avail/20-upmix.conf ~/.config/pipewire/client.conf.d
    check_success "copying the upmix configuration for client-rt"

    log_success "Pipewire has been successfully configured"
}

# Функция для оптимизации GNOME
optimize_gnome() {
    log_message "GNOME optimization..."

    # Маскирование ненужных служб GNOME
    log_message "Masking unnecessary GNOME services..."

    systemctl --user mask org.gnome.SettingsDaemon.Wacom.service org.gnome.SettingsDaemon.Smartcard.service
    check_success "masking unnecessary GNOME services"

    log_success "GNOME has been successfully optimized"
}

# Функция для настройки ZSH
configure_zsh() {
    log_message "ZSH configuration..."

    cp -f ./files/zsh/zsh_history ~/.zsh_history
    cp -f ./files/zsh/zshrc ~/.zshrc
    check_success "creating ZSH configuration files"

    log_success "ZSH has been successfully configured"
}

# Функция для настройки цвета папок для темы Papirus
configure_papirus_folder_colors() {
    log_message "Papirus folder colors..."

    papirus-folders -C cyan --theme Papirus-Dark
    check_success "change color of folders in Papirus theme"

    log_success "Papirus folder colors have been successfully changed"
}

# Функция для настройки формата вывода в fastfetch
configure_fastfetch() {
    log_message "Fastfetch format..."

    cp -f ./files/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc
    check_success "creating a configuration fastfetch file"

    log_success "Fastfetch has been successfully configured"
}

# Функция копирования данных по LM Studio
configure_lmstudio() {
   log_message "LM Studio data..."

    cp -f ./files/lmstudio/config-presets ~/.lmstudio/config-presets/
    cp -f ./files/lmstudio/conversations ~/.lmstudio/conversations/
    check_success "creating a configuration fastfetch file"

    log_success "LM Studio data has been successfully transfered"
}

# Функция для удаления всех lib32-пакетов (актуально если всё основное ПО через Flatpak)
configure_lib32() {
    log_message "Delete all lib32 packages..."

     pacman -Rs $(pacman -Qq | grep '^lib32')
     check_success "delete lib32"

     log_success "All lib32 packages has been successfully deleted"
}

# Основная функция
main() {
    log_message "The beginning of the process of optimizing Arch Linux user settings (Part 4)..."

    configure_pipewire
    optimize_gnome
    configure_zsh
    configure_papirus_folder_colors
    configure_fastfetch
    configure_lmstudio
    configure_lib32

    log_message "All operations have been completed successfully!"
    log_success "===== END OF THE 4TH PART ====="
}

# Запуск основной функции
main
