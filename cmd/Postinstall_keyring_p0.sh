#!/bin/bash

# =====================================================
# Скрипт для обновления ключей и зеркал Arch Linux. Часть 0
# =====================================================

# Включаем строгий режим для bash
set -e  # Скрипт завершится при любой ошибке
set -u  # Использование неопределенных переменных вызовет ошибку

# Функция для вывода сообщений
log_message() {
   echo -e "\e[1;34m[INFO]\e[0m $1"
}

# Функция для вывода сообщений об ошибках
log_error() {
   echo -e "\e[1;31m[ERROR]\e[0m $1" >&2
}

# Функция для вывода сообщений об успешном выполнении
log_success() {
   echo -e "\e[1;32m[SUCCESS]\e[0m $1"
}

# Функция для проверки успешности выполнения команды
check_success() {
   if [ $? -ne 0 ]; then
      log_error "Ошибка при выполнении: $1"
      exit 1
   fi
}

# Проверка наличия прав суперпользователя
if [[ $EUID -ne 0 ]]; then
   log_error "Этот скрипт должен быть запущен с правами суперпользователя"
   echo "Используйте: sudo $0"
   exit 1
fi

# Функция для обновления зеркал
update_mirrors() {
   log_message "Обновление списка зеркал..."

   # Установка reflector, если он не установлен
   if ! pacman -Q reflector &>/dev/null; then
      log_message "Установка reflector и rsync..."
      pacman -S --noconfirm reflector rsync
      check_success "установка reflector и rsync"
   fi

   # Создание резервной копии текущего списка зеркал
   cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
   log_message "Резервная копия текущего списка зеркал сохранена в /etc/pacman.d/mirrorlist.backup"

   # Обновление списка зеркал
   log_message "Выбор 13 самых быстрых зеркал..."
   reflector --country Germany,Norway,Russia,Finland --latest 13 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
   check_success "обновление списка зеркал"

   log_success "Список зеркал успешно обновлен"
}

# Функция для настройки автоматического обновления зеркал
setup_mirror_update_timer() {
   log_message "Настройка автоматического обновления зеркал..."

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
   check_success "перезагрузка конфигурации systemd"

   # Включаем и запускаем таймер
   systemctl enable mirror-update.timer
   check_success "включение таймера обновления зеркал"

   systemctl start mirror-update.timer
   check_success "запуск таймера обновления зеркал"

   log_success "Автоматическое обновление зеркал настроено (раз в неделю)"
}

# Функция для обновления ключей
update_keys() {
   log_message "Обновление ключей Arch Linux..."

   # Инициализация ключей
   log_message "Инициализация ключей..."
   pacman-key --init
   check_success "инициализация ключей"

   # Заполнение ключей
   log_message "Заполнение ключей Arch Linux..."
   pacman-key --populate archlinux
   check_success "заполнение ключей"

   # Обновление ключей (длительная операция)
   log_message "Обновление ключей (это может занять некоторое время)..."
   pacman-key --refresh-keys
   check_success "обновление ключей"

   # Синхронизация баз данных пакетов
   log_message "Синхронизация баз данных пакетов..."
   pacman -Sy
   check_success "синхронизация баз данных"

   # Настройка автоматического обновления ключей
   log_message "Настройка автоматического обновления ключей..."
   systemctl enable --now archlinux-keyring-wkd-sync.timer
   check_success "включение таймера обновления ключей"

   systemctl start archlinux-keyring-wkd-sync.service
   check_success "запуск службы обновления ключей"

   log_success "Ключи Arch Linux успешно обновлены"
}

# Основная часть скрипта
main() {
   log_message "Начало процесса обновления системы Arch Linux..."

   update_mirrors
   setup_mirror_update_timer
   update_keys

   log_success "Все операции успешно завершены!"
}

# Запуск основной функции
main