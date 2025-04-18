#!/bin/bash

# =====================================================
# Скрипт для завершающих работ по Arch Linux. Часть 5
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

# 1. Функция очистки лишних пакетов
delete_old_packages() {
   log_message "Cleaning of excess packages..."

   # Временно отключаем режим завершения при ошибке
   set +e

   # Очистка кэша пакетов
   pacman -Scc --noconfirm
   if [ $? -ne 0 ]; then
      log_warning "Failed to clear the packet cache, but continue execution"
   fi

   # Удаление ненужных пакетов
   ORPHANS=$(pacman -Qtdq)
   if [ -n "$ORPHANS" ]; then
      pacman -Rscn $ORPHANS --noconfirm
      if [ $? -ne 0 ]; then
         log_warning "It was not possible to delete some unnecessary packages, but we continue to execute"
      fi
   else
      log_message "No unnecessary packages were found."
   fi

   # Включаем режим завершения при ошибке обратно
   set -e

   log_success "Cleaning of excess packages is completed"
}

# 2. Функция повтрного обновления initramfs и grub-загрузчик
upd_init() {
   log_message "Updating initramfs and the grub loader..."

   mkinitcpio -P && grub-mkconfig -o /boot/grub/grub.cfg
   check_success "updating initramfs and the grub loader"

   log_success "initramfs and grub loader have been updated successfully"
}

# Основная функция
main() {
   log_message "The beginning of the completion process for Arch Linux (Part 5)..."

   delete_old_packages
   upd_init

   log_success "===== END OF THE 5TH PART ====="
   log_warning "Installation and optimization are complete. It is recommended to reboot the system!"
}

# Запуск основной функции
main