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
NVIDIA_PRESENT=false

# Выполняем проверку один раз и сохраняем результат
if has_nvidia; then
   NVIDIA_PRESENT=true
fi

# Проверка наличия прав суперпользователя
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run with superuser rights"
   echo "Use: sudo $0"
   exit 1
fi

# Функция для настройки initramfs
configure_initramfs() {
   log_message "Configuring initramfs images..."

   # Ускорение загрузки системы c помощью systemd
   sed -i 's/HOOKS=.*/HOOKS=(systemd autodetect modconf microcode kms keyboard keymap sd-vconsole block filesystems)/' /etc/mkinitcpio.conf
   sed -i 's/#COMPRESSION="lz4"/COMPRESSION="lz4"/' /etc/mkinitcpio.conf
   sed -i 's/#COMPRESSION_OPTIONS=()/COMPRESSION_OPTIONS=(-9)/' /etc/mkinitcpio.conf
   check_success "setting up hooks to speed up the download"

   log_success "initramfs images have been successfully configured"
}

# Функция для настройки загрузчика GRUB
configure_bootloader() {
   log_message "Configuring the boot loader..."

   cp -f ./files/loader.conf /boot/loader/loader.conf
   check_success "configuring the boot params"

   sed -i 's/^options.*/options rw quiet splash/' /boot/loader/entries/arch-linux.conf
   check_success "configuring the kernel parameters"

   log_success "The boot loader has been successfully configured"
}

# Функция для настройки параметров ядра
configure_sysctl() {
   log_message "Configuring kernel parameters via sysctl..."

   cat << EOF > /etc/sysctl.d/99-sysctl.conf
# Оптимизация памяти для игр и мультимедиа
vm.swappiness=100
vm.vfs_cache_pressure=50
vm.page-cluster=0

# Оптимизация ядра в рантайме
kernel.split_lock_mitigate=0
kernel.nmi_watchdog=0

# Улучшение сетевой производительности для онлайн-игр
net.core.netdev_max_backlog=32768
net.core.default_qdisc=fq_codel
net.ipv4.ip_local_port_range=1024 65000
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_notsent_lowat=16384
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=30

# Оптимизация для FS и SSD
vm.dirty_background_bytes=67108864  # 1/4 от vm.dirty_bytes
vm.dirty_bytes=268435456            # пропускная способность SSD
vm.dirty_expire_centisecs=1300      # 13 секунд и вызов записи грязных страниц
vm.dirty_writeback_centisecs=100    # 1 секунд между периодами работы потоков по гразным страницам
EOF
   check_success "creating a sysctl configuration"

   log_success "The kernel parameters have been successfully configured"
}

# Функция для настройки переменных окружения (NVIDIA)
configure_wayland() {
   log_message "Setting up environment variables..."

   # Дополнение /etc/environment
   if $NVIDIA_PRESENT; then
      cat << EOF >> /etc/environment
#
# This file is parsed by pam_env module
#
# Syntax: simple "KEY=VAL" pairs on separate lines
#
# --- Аппаратное ускорение видео (NVDEC/NVENC) ---
LIBVA_DRIVER_NAME=nvidia
# --- Оптимизации для игр (NVIDIA) ---
__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
# Не очищать кэш шейдеров (сохраняется между сессиями)
__GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
#
# При проблемах с раcкрытием окон на весь экран
# GSK_RENDERER=cairo
EOF
   fi
   check_success "setting up environment variables"

   log_success "Environment variable settings have been successfully configured"
}

# Функция для настройки Plex Media Server
configure_plex() {
   log_message "The Plex Media Server add-on..."

   # Устанавливаем владельца над папкой
   chown -R plex:plex /media
   check_success "setting the owner rights for the /media folder"

   # Добавляем права самой родительской папке
   chmod -R 775 /media
   check_success "setting access rights for the /media folder"

   # Настраиваем службу
   systemctl enable plexmediaserver.service
   check_success "enabling the Plex Media Server service"

   systemctl start plexmediaserver.service
   check_success "launching the Plex Media Server service"

   log_success "Plex Media Server has been successfully configured"
}

# Функция для установки и настройки системных служб
configure_system_services() {
   log_message "Configuring system services and daemons..."

   systemctl daemon-reload
   check_success "restarting the systemd configuration"

   # Настройка zram
   log_message "Creating a zram configuration..."
   cat << EOF > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF
   check_success "creating a zram configuration"

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
   check_success "creating a v2raya service configuration"

   # Включение и запуск системных служб
   log_message "Enabling system services..."
   systemctl enable paccache.timer bluetooth.service v2raya.service power-profiles-daemon thermald cronie.service irqbalance ananicy-cpp earlyoom #nvidia-powerd
   #systemd-zram-setup@zram0.service
   check_success "enabling system services"

   log_message "Launching system services..."
   systemctl start bluetooth.service v2raya.service
   #systemd-zram-setup@zram0.service
   check_success "launching system services"

   # Настройка еженедельной очистки кэша pacman
   # Удаляем таймер, если он существует
   if systemctl status pacman-cleaner.timer &>/dev/null; then
      log_message "Deleting an existing pacman-cleaner.timer..."

      systemctl stop pacman-cleaner.timer
      check_success "stop pacman-cleaner.timer"

      systemctl disable pacman-cleaner.timer
      check_success "disable pacman-cleaner.timer"

      rm -f /etc/systemd/system/pacman-cleaner.timer
      check_success "delete pacman-cleaner.timer"
   fi

   # Создаем новый таймер
   log_message "Creating a timer for clearing the pacman cache..."

   systemd-run --on-calendar="Sun 10:00" --unit="pacman-cleaner" /sbin/pacman -Scc
   check_success "setting up a weekly pacman cache cleanup"

   # Перезагрузка конфигурации systemd
   log_message "Restarting the systemd configuration..."

   systemctl daemon-reload
   check_success "restarting the systemd configuration"

   log_success "System services and daemons have been successfully configured"
}

# Функция для настройки NVIDIA
configure_nvidia() {
   if ! $NVIDIA_PRESENT; then
      log_message "The NVIDIA graphics card is not detected. Skipping NVIDIA settings"
      return 0
   fi

   log_message "Setting up NVIDIA..."

   # Правка конфига nvidia.conf
   log_message "Configuring NVIDIA configuration..."

   cat << EOF >> /etc/modprobe.d/nvidia.conf
# Параметры PCIe
options nvidia NVreg_UsePageAttributeTable=1 NVreg_EnableResizableBar=1

# Управление питанием (умеренный режим)
options nvidia NVreg_DynamicPowerManagement=0x01

# Параметры производительности
options nvidia NVreg_ResmanDebugLevel=0 NVreg_PreserveVideoMemoryAllocations=0
EOF
   check_success "creating a new nvidia.conf config"

   log_success "NVIDIA has been successfully configured"
}

# Функция для замены bash на zsh
change_shell_to_zsh() {
   log_message "Replacing bash with zsh..."

   chsh -s /bin/zsh
   check_success "replacing the shell with zsh"

   log_success "Shell successfully changed to zsh"
}

# Функция для отключения планировщика для систем с NVMe SSD
disable_nvmesh_scheduler() {
   if lsblk -d -o name | grep -iq 'nvm'; then
      log_message "Disabling the NVMe SSD scheduler..."
      cat << EOF > /etc/udev/rules.d/60-ioschedulers.rules
# NVMe SSD
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
EOF
      check_success "disabling the NVMe scheduler"

      log_success "The NVMe SSD scheduler successfully disabled"
   fi
}

# Функция для корректной настройки приоритетов при работе с аудио
configure_realtime_audio() {
   log_message "Configure realtime audio priority..."

   mkdir -p /etc/security/limits.d
   cat << EOF > /etc/security/limits.d/20-rt-audio.conf
@audio - rtprio 98
EOF
   check_success "creating realtime config"

   log_success "Configure realtime audio priority successfully created"
}

# Функция для настройки OOM
configure_earlyoom() {
   log_message "Setting up earlyoom rules..."

   cat << EOF >> /etc/default/earlyoom
# Default settings for earlyoom. This file is sourced by /bin/sh from
# /etc/init.d/earlyoom or by systemd from earlyoom.service.

# Options to pass to earlyoom
EARLYOOM_ARGS="-r 0 -m 10 -s 20 --avoid '(^|/)(systemd|sshd|gnome-shell|pipewire)$'"

# Examples:

# Print memory report every minute instead of every hour
# EARLYOOM_ARGS="-r 60"

# Available minimum memory 5%
# EARLYOOM_ARGS="-m 5"

# Available minimum memory 15% and free minimum swap 5%
# EARLYOOM_ARGS="-m 15 -s 5"

# Avoid killing processes whose name matches this regexp
# EARLYOOM_ARGS="--avoid '(^|/)(init|X|sshd|firefox)$'"

# See more at `earlyoom -h'
EOF
   check_success "setting up environment variables"

   log_success "Earlyoom settings have been successfully configured"
}

# Функция для настройки альтернативного планировщика
configure_sched() {
   log_message "Setting up alternative SCX scheduler..."

   cat << EOF >> /etc/scx_loader.toml
default_sched = "scx_bpfland" # Edit this line to the scheduler you want scx_loader to start at boot
default_mode = "LowLatency" # Possible values: "Auto", "Gaming", "LowLatency", "PowerSave".
EOF
    systemctl enable --now scx_loader.service
    check_success "setting up alternative SCX scheduler"

   log_success "Alternaive SCX scheduler have been successfully configured"
}

# Основная функция
main() {
   log_message "The beginning of the Arch Linux optimization and configuration process (Part 3)..."

   # Вывод информации о наличии NVIDIA
   if $NVIDIA_PRESENT; then
      log_message "An NVIDIA graphics card has been detected. The appropriate settings will be applied."
   else
      log_message "No NVIDIA graphics card detected. NVIDIA settings will be skipped."
   fi

   configure_initramfs
   configure_bootloader
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

   log_message "All operations have been completed successfully!"
   log_success "===== END OF THE 3D PART ====="
}

# Запуск основной функции
main
