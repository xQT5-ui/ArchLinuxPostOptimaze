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

# Проверка наличия прав суперпользователя
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run with superuser rights"
   echo "Use: sudo $0"
   exit 1
fi

# Функция для обновления зеркал
update_mirrors() {
   log_message "Updating the list of mirrors..."

   # Установка reflector, если он не установлен
   if ! pacman -Q reflector &>/dev/null; then
      log_message "Installing reflector and rsync..."
      pacman -S --noconfirm reflector rsync
      check_success "installing reflector and rsync"
   fi

   # Создание резервной копии текущего списка зеркал
   cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
   log_message "A backup copy of the current list of mirrors is saved in /etc/pacman.d/mirrorlist.backup"

   # Обновление списка зеркал
   log_message "A selection of the 13 fastest mirrors..."
   reflector --country Germany,Norway,Russia,Finland --latest 13 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
   check_success "updating the mirror list"

   log_success "The list of mirrors has been successfully updated"
}

# Функция для настройки автоматического обновления зеркал
setup_mirror_update_timer() {
   log_message "Setting up automatic mirror updates..."

   # Создаем директорию для пользовательских сервисов, если её нет
   mkdir -p /etc/systemd/system

   # Создаем файл сервиса для обновления зеркал
   cat > /etc/systemd/system/mirror-update.service << EOF
[Unit]
Description=Update Arch Linux mirrorlist
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/reflector --country Germany,Norway,Russia,Finland --latest 13 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
ExecStartPost=/usr/bin/pacman -Syy

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
   check_success "restarting the systemd configuration"

   # Включаем и запускаем таймер
   systemctl enable mirror-update.timer
   check_success "turning on the mirror refresh timer"

   systemctl start mirror-update.timer
   check_success "starting the mirror update timer"

   log_success "Automatic mirror updates are set up (once a week)"
}

# Функция для обновления ключей
update_keys() {
   log_message "Updating Arch Linux keys..."

   # Инициализация ключей
   log_message "Initialization of keys..."
   pacman-key --init
   check_success "initialization of keys"

   # Заполнение ключей
   log_message "Filling in Arch Linux keys..."
   pacman-key --populate archlinux
   check_success "filling in keys"

   # Обновление ключей (длительная операция)
   log_message "Updating the keys (it may take some time)..."
   pacman-key --refresh-keys
   check_success "updating the keys"

   # Синхронизация баз данных пакетов
   log_message "Synchronization of package databases..."
   pacman -Sy
   check_success "synchronization of package databases"

   # Настройка автоматического обновления ключей
   log_message "Setting up automatic key updates..."
   systemctl enable --now archlinux-keyring-wkd-sync.timer
   check_success "enabling the key update timer"

   systemctl start archlinux-keyring-wkd-sync.service
   check_success "launching the key update service"

   log_success "Arch Linux keys have been successfully updated"
}

# Основная часть скрипта
main() {
   log_message "The beginning of the database configuration process for subsequent updates of the Arch Linux system..."

   update_mirrors
   setup_mirror_update_timer
   update_keys

   log_success "All operations have been completed successfully!"
}

# Запуск основной функции
main