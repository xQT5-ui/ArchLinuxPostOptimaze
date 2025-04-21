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

# 1. Функция для настройки initramfs
configure_initramfs() {
   log_message "Configuring initramfs images..."

   # Ускорение загрузки системы c помощью systemd
   sed -i 's/HOOKS=.*/HOOKS=(systemd autodetect modconf microcode kms keyboard keymap sd-vconsole block filesystems)/' /etc/mkinitcpio.conf
   check_success "setting up hooks to speed up the download"

   log_success "initramfs images have been successfully configured"
}

# 2. Функция для настройки загрузчика GRUB
configure_bootloader() {
   log_message "Configuring the GRUB loader..."

   sed -i 's/^GRUB_TIMEOUT=[0-9]\+/GRUB_TIMEOUT=1/' /etc/default/grub
   check_success "configuring the GRUB timeout"

   sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=countdown/' /etc/default/grub
   check_success "configuring the GRUB timeout style"

   sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash zswap.enabled=0 tsc=reliable intel_pstate=active"/' /etc/default/grub
   check_success "configuring the kernel parameters"

   log_success "The GRUB loader has been successfully configured"
}

# 3. Функция для настройки параметров ядра
configure_sysctl() {
   log_message "Configuring kernel parameters via sysctl..."

   cat << EOF > /etc/sysctl.d/99-sysctl.conf
# Оптимизация памяти для игр и мультимедиа
vm.swappiness=150 # выше 100 при использовании zram
vm.vfs_cache_pressure=50
#vm.max_map_count=262144

# Улучшение сетевой производительности для онлайн-игр
net.core.netdev_max_backlog=32768
#net.ipv4.tcp_fastopen=3
net.ipv4.ip_local_port_range=1024 65000
net.core.default_qdisc=fq_codel
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_notsent_lowat=16384
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=30

# Оптимизация для Btrfs и SSD
vm.dirty_background_bytes=10485760  # 10 МБ
vm.dirty_bytes=20971520  # 20 МБ
EOF
   check_success "creating a sysctl configuration"

   log_success "The kernel parameters have been successfully configured"
}

# 4. Функция для настройки переменных окружения (NVIDIA)
configure_wayland() {
   log_message "Setting up environment variables..."

   # Дополнение /etc/environment
   if $NVIDIA_PRESENT; then
      cat << EOF >> /etc/environment
# Основные настройки NVIDIA для Wayland
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
LIBVA_DRIVER_NAME=nvidia
__GL_MaxFramesAllowed=1 # Ограничивает кадры в фоновых окнах (аналог Nvidia Frame Rate Limiter)
#
# Аппаратное ускорение видео (дополнение к существующим)
VDPAU_DRIVER=nvidia  # Для декодирования видео через VDPAU
NVD_BACKEND=direct  # Прямой доступ к GPU для Vulkan-приложений
VDPAU_NVIDIA_ENABLE_NVDEC=1
#
# При проблемах с раcкрытием окон на весь экран
# GSK_RENDERER=cairo
EOF
   fi
   check_success "setting up environment variables"

   log_success "Environment variable settings have been successfully configured"
}

# 5. Функция для настройки Plex Media Server
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

# 6. Функция для установки и настройки системных служб
configure_system_services() {
   log_message "Configuring system services and daemons..."

   systemctl daemon-reload
   check_success "restarting the systemd configuration"

   # Настройка zram
   log_message "Creating a zram configuration..."
   cat << EOF > /etc/systemd/zram-generator.conf
[zram0]
# Размер zram
zram-size = min(ram / 2, 8192)
# Алгоритм сжатия (zstd быстрее lz4 на 5-10%, но требует чуть больше CPU)
compression-algorithm = zstd
# Отключить zswap для предотвращения конфликтов
disable-zswap = true
# Высший приоритет
swap-priority = 100
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
   systemctl enable paccache.timer systemd-zram-setup@zram0.service bluetooth.service v2raya.service power-profiles-daemon thermald systemd-oomd cronie.service
   check_success "enabling system services"

   log_message "Launching system services..."
   systemctl start systemd-zram-setup@zram0.service bluetooth.service v2raya.service
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

# 7. Функция для настройки NVIDIA
configure_nvidia() {
   if ! $NVIDIA_PRESENT; then
      log_message "The NVIDIA graphics card is not detected. Skipping NVIDIA settings"
      return 0
   fi

   log_message "Setting up NVIDIA..."

   # Включение envycontrol в режиме NVIDIA
   log_message "Enabling envycontrol in NVIDIA mode..."

   envycontrol -s nvidia --force-comp
   check_success "enabling envycontrol in NVIDIA mode"

   # Правка конфига nvidia.conf
   log_message "Configuring NVIDIA configuration..."

   rm -f /etc/modprobe.d/nvidia.conf
   check_success "deleting the old nvidia.conf config"

   cat << EOF > /etc/modprobe.d/nvidia.conf
options nvidia NVreg_EnableStreamMemOPs=0
options nvidia NVreg_UseThreadedOptimizations=1
options nvidia NVreg_EnableMSI=1 # Включает Message-Signaled Interrupts для снижения задержек. Актуально для PCIe Gen3+
options nvidia NVreg_UsePageAttributeTable=1 # Улучшает управление памятью через PAT
options nvidia NVreg_PreserveVideoMemoryAllocations=1  # Сохранение видеопамяти при suspend
options nvidia NVreg_EnableGpuFirmware=1  # Аппаратная инициализация для RTX >30xx
options nvidia NVreg_EnableHostAllocation=1    # +7% VRAM perf
options nvidia NVreg_EnableResizableBar=1     # PCIe Resizable BAR
options nvidia NVreg_RequireECC=0             # Для не-серверных GPU
#options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1" # Приоритет производительности
EOF
   check_success "creating a new nvidia.conf config"

   # Включение служб NVIDIA
   systemctl enable nvidia-resume nvidia-suspend nvidia-hibernate
   check_success "enabling NVIDIA services"

   # Перезагрузка конфигурации systemd
   log_message "Restarting the systemd configuration..."

   systemctl daemon-reload
   check_success "restarting the systemd configuration"

   log_success "NVIDIA has been successfully configured"
}

# 8. Функция для замены bash на zsh
change_shell_to_zsh() {
   log_message "Replacing bash with zsh..."

   chsh -s $(which zsh)
   check_success "replacing the shell with zsh"

   log_success "Shell successfully changed to zsh"
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

   log_message "All operations have been completed successfully!"
   log_success "===== END OF THE 3D PART ====="
}

# Запуск основной функции
main
