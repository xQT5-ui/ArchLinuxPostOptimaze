#!/bin/bash

# =====================================================
# Скрипт для оптимизации пользовательских настроек Arch Linux. Часть 4
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

# Функция для настройки Pipewire
configure_pipewire() {
    log_message "Setting up and enabling Pipewire..."

    # Включение служб Pipewire
    #systemctl --user enable pipewire pipewire-pulse wireplumber

    # Создание директорий для конфигурации
    mkdir -p $HOME/.config/pipewire/pipewire.conf.d $HOME/.config/pipewire/pipewire-pulse.conf.d $HOME/.config/pipewire/client.conf.d

    # Создание конфигурационного файла для звука
    cp -f ./child/files/pipewire/10-sound.conf $HOME/.config/pipewire/pipewire.conf.d
    # Копирование дополнительных конфигурационных файлов
    cp /usr/share/pipewire/client.conf.avail/20-upmix.conf $HOME/.config/pipewire/pipewire-pulse.conf.d
    cp /usr/share/pipewire/client.conf.avail/20-upmix.conf $HOME/.config/pipewire/client.conf.d
}

# Функция для оптимизации GNOME
optimize_gnome_services() {
    log_message "GNOME optimization..."

    # Маскирование ненужных служб GNOME
    systemctl --user mask org.gnome.SettingsDaemon.Wacom.service org.gnome.SettingsDaemon.Smartcard.service
}

# Функция для настройки ZSH
configure_zsh() {
    log_message "ZSH configuration..."

    cp -f ./child/files/user/zsh/zsh_history $HOME/.zsh_history
    cp -f ./child/files/zsh/zshrc $HOME/.zshrc
    cp -f ./child/files/zsh/p10k.zsh $HOME/.p10k.zsh

    # Устанавливаем правильные права на файлы ZSH
    chown $USER:$USER $HOME/.zshrc $HOME/.zsh_history $HOME/.p10k.zsh
}

# Функция для настройки цвета папок для темы Papirus
configure_papirus_folder_colors() {
    log_message "Set Papirus folder colors..."

     if command -v papirus-folders > /dev/null 2>&1; then
        papirus-folders -C cyan --theme Papirus-Dark
    else
        log_warning "WARNING: papirus-folders not found in PATH. Skipping configuration."
    fi
}

# Функция для настройки формата вывода в fastfetch
configure_fastfetch() {
    log_message "Set Fastfetch output format..."

    cp -f ./child/files/user/fastfetch/config.jsonc $HOME/.config/fastfetch/config.jsonc
}

# Функция копирования данных по LM Studio
configure_lmstudio() {
    log_message "Transfer LM Studio data..."

    mkdir $HOME/.lmstudio
    cp -rf ./child/files/user/lmstudio/config-presets $HOME/.lmstudio/
    cp -rf ./child/files/user/lmstudio/conversations $HOME/.lmstudio/
}

# Функция копирования данных по Zen
configure_zen() {
    log_message "Transfer Zen data..."

    cp -rf ./child/files/user/zen $HOME/.zen/
}

# Функция копирования данных по Flatpak
configure_flatpak() {
    log_message "Transfer Flatpak data..."

    cp -rf ./child/files/user/flatpak/overrides $HOME/.local/share/flatpak/overrides
}

# Основная функция
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

    log_success "All operations have been completed successfully!"
    log_message "===== END OF THE 4TH PART ====="
}

# Запуск основной функции
main
