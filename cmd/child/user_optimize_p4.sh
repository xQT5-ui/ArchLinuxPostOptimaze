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

# Функция для настройки Pipewire
configure_pipewire() {
    log_message "Setting up and enabling Pipewire..."

    # Включение служб Pipewire
    systemctl --user enable --now pipewire pipewire.socket pipewire-pulse wireplumber

    # Создание директорий для конфигурации
    mkdir -p $HOME/.config/pipewire/pipewire.conf.d $HOME/.config/pipewire/pipewire-pulse.conf.d $HOME/.config/pipewire/client.conf.d

    # Создание конфигурационного файла для звука
    cp -f ./child/files/pipewire/10-sound.conf $HOME/.config/pipewire/pipewire.conf.d
    # Копирование дополнительных конфигурационных файлов
    cp /usr/share/pipewire/client.conf.avail/20-upmix.conf $HOME/.config/pipewire/pipewire-pulse.conf.d
    cp /usr/share/pipewire/client.conf.avail/20-upmix.conf $HOME/.config/pipewire/client.conf.d
}

# Функция для оптимизации GNOME
optimize_gnome() {
    log_message "GNOME optimization..."

    # Маскирование ненужных служб GNOME
    systemctl --user mask org.gnome.SettingsDaemon.Wacom.service org.gnome.SettingsDaemon.Smartcard.service
}

# Функция для настройки ZSH
configure_zsh() {
    log_message "ZSH configuration..."

    cp -f ./child/files/zsh/zsh_history $HOME/.zsh_history
    cp -f ./child/files/zsh/zshrc $HOME/.zshrc

    # Устанавливаем правильные права на файлы ZSH
    touch $HOME/.zshrc $HOME/.zsh_history
    chown $USER:$USER $HOME/.zshrc $HOME/.zsh_history
}

# Функция для настройки цвета папок для темы Papirus
configure_papirus_folder_colors() {
    log_message "Set Papirus folder colors..."

    papirus-folders -C cyan --theme Papirus-Dark
}

# Функция для настройки формата вывода в fastfetch
configure_fastfetch() {
    log_message "Set Fastfetch output format..."

    cp -f ./child/files/fastfetch/config.jsonc $HOME/.config/fastfetch/config.jsonc
}

# Функция копирования данных по LM Studio
configure_lmstudio() {
    log_message "Transfer LM Studio data..."

    cp -f ./child/files/lmstudio/config-presets $HOME/.lmstudio/config-presets/
    cp -f ./child/files/lmstudio/conversations $HOME/.lmstudio/conversations/
}

# Основная функция
main() {
    log_message "User settings optimize (Part 4)..."

    configure_pipewire
    optimize_gnome
    configure_zsh
    configure_papirus_folder_colors
    configure_fastfetch
    configure_lmstudio

    log_success "All operations have been completed successfully!"
    log_message "===== END OF THE 4TH PART ====="
}

# Запуск основной функции
main
