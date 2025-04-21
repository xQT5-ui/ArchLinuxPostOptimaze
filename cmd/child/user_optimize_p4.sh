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

# 1. # Функция для настройки PipeWire
configure_pipewire() {
   log_message "Setting up and enabling PipeWire..."

   # Включение служб PipeWire
   systemctl --user enable --now pipewire pipewire.socket pipewire-pulse wireplumber
   check_success "enabling PipeWire"

   # Создание директорий для конфигурации
   mkdir -p ~/.config/pipewire/pipewire.conf.d ~/.config/pipewire/pipewire-pulse.conf.d ~/.config/pipewire/client.conf.d
   check_success "creating directories for PipeWire configuration"

   # Создание конфигурационного файла для звука
   cat << EOF > ~/.config/pipewire/pipewire.conf.d/10-sound.conf
context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 512
    default.clock.min-quantum = 32
    default.clock.max-quantum = 2048
    default.clock.allowed-rates = [ 44100 48000 88200 96000 176400 192000 ]
    default.clock.power-of-two-quantum = true
    support.node.latency = true
}

stream.properties = {
    node.latency = 512/48000
    node.autoconnect = true
    resample.quality = 14
}
EOF
   check_success "creating a configuration file for audio"

   # Копирование дополнительных конфигурационных файлов
   cp /usr/share/pipewire/client.conf.avail/20-upmix.conf ~/.config/pipewire/pipewire-pulse.conf.d
   check_success "copying the upmix configuration for pipewire-pulse"

   cp /usr/share/pipewire/client.conf.avail/20-upmix.conf ~/.config/pipewire/client.conf.d
   check_success "copying the upmix configuration for client-rt"

   log_success "PipeWire has been successfully configured"
}

# 2. Функция для оптимизации GNOME
optimize_gnome() {
   log_message "GNOME optimization..."

   # Маскирование ненужных служб GNOME
   log_message "Masking unnecessary GNOME services..."

   systemctl --user mask org.gnome.SettingsDaemon.Wacom.service org.gnome.SettingsDaemon.Smartcard.service
   check_success "masking unnecessary GNOME services"

   log_success "GNOME has been successfully optimized"
}

# 3. Функция для настройки ZSH
configure_zsh() {
   log_message "ZSH configuration..."

   touch ~/.zshrc ~/.zsh_history
   check_success "creating ZSH configuration files"

   cat << EOF > ~/.zshrc
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh" ]]; then
  source "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh"
fi

source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# История команд для zsh
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY

# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
   check_success "creating a configuration file .zshrc"

   log_success "ZSH has been successfully configured"
}

# Основная функция
main() {
   log_message "The beginning of the process of optimizing Arch Linux user settings (Part 4)..."

   configure_pipewire
   optimize_gnome
   configure_zsh

   log_message "All operations have been completed successfully!"
   log_success "===== END OF THE 4TH PART ====="
}

# Запуск основной функции
main