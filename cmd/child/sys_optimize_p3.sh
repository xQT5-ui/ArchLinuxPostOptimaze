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
      log_error "Ошибка при выполнении: $1"
      exit 1
   fi
}

# Функция для проверки наличия видеокарты NVIDIA
has_nvidia() {
   log_message "Проверка наличия видеокарты NVIDIA..."

   # Способ 1: Проверка через lspci
   if lspci | grep -i nvidia > /dev/null; then
      log_success "Обнаружена видеокарта NVIDIA"
      return 0  # В bash 0 означает "истина" (успех)
   fi

   # Способ 2: Проверка через наличие модуля ядра
   if lsmod | grep -i nvidia > /dev/null; then
      log_success "Обнаружен драйвер NVIDIA"
      return 0
   fi

   log_message "Видеокарта NVIDIA не обнаружена"
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
   log_error "Этот скрипт должен быть запущен с правами суперпользователя"
   echo "Используйте: sudo $0"
   exit 1
fi

# 1. Функция для настройки initramfs
configure_initramfs() {
   log_message "Настройка образов initramfs..."

   # Добавление важных модулей (с проверкой на NVIDIA)
   if $NVIDIA_PRESENT; then
      echo "MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm btrfs)" > /etc/mkinitcpio.conf.d/10-modules.conf
   else
      echo "MODULES+=(btrfs)" > /etc/mkinitcpio.conf.d/10-modules.conf
   fi
   check_success "добавление модулей в initramfs"

   # Ускорение загрузки системы c помощью systemd
   sed -i 's/HOOKS=.*/HOOKS=(systemd autodetect modconf microcode kms keyboard keymap sd-vconsole block filesystems)/' /etc/mkinitcpio.conf
   check_success "настройка хуков для ускорения загрузки"

   log_success "Образы initramfs успешно настроены"
}

# 2. Функция для повышения системных лимитов
increase_system_limits() {
   log_message "Повышение системных лимитов..."

   sed -i 's/.*DefaultLimitNOFILE=.*/DefaultLimitNOFILE=1046576/' /etc/systemd/system.conf
   check_success "настройка лимитов в system.conf"

   sed -i 's/.*DefaultLimitNOFILE=.*/DefaultLimitNOFILE=1046576/' /etc/systemd/user.conf
   check_success "настройка лимитов в user.conf"

   sed -i '/#@student        -       maxlogins       4/a '"$SUDO_USER"' hard nofile 1046576' /etc/security/limits.conf
   check_success "настройка лимитов в limits.conf"

   log_success "Системные лимиты успешно повышены"
}

# 3. Функция для настройки загрузчика GRUB
configure_bootloader() {
   log_message "Настройка загрузчика GRUB..."

   sed -i 's/^GRUB_TIMEOUT=[0-9]\+/GRUB_TIMEOUT=1/' /etc/default/grub
   check_success "настройка таймаута GRUB"

   if $NVIDIA_PRESENT; then
      sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia-drm.modeset=1 modprobe.blacklist=nouveau zswap.enabled=0 tsc=reliable threadirqs intel_pstate=active"/' /etc/default/grub
   else
      sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash zswap.enabled=0 tsc=reliable threadirqs intel_pstate=active"/' /etc/default/grub
   fi
   check_success "настройка параметров ядра"

   sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=countdown/' /etc/default/grub
   check_success "настройка стиля таймаута GRUB"

   log_success "Загрузчик GRUB успешно настроен"
}

# 4. Функция для настройки параметров ядра
configure_sysctl() {
   log_message "Настройка параметров ядра через sysctl..."

   cat << EOF > /etc/sysctl.d/99-sysctl.conf
# Оптимизация памяти для игр и мультимедиа
vm.swappiness=20 # 100 - активно использовано zram
vm.vfs_cache_pressure=50
vm.max_map_count=262144

# Параметр для предотвращения OOM
vm.min_free_kbytes=131072 # 128 МБ

# Улучшение сетевой производительности для онлайн-игр
net.core.netdev_max_backlog=32768
net.core.somaxconn=4096
net.ipv4.tcp_fastopen=3
net.ipv4.ip_local_port_range=1024 65000
net.core.default_qdisc=fq_codel
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_notsent_lowat=16384
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=30

# Оптимизация UDP для игр
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default=16777216
net.core.wmem_default=16777216
net.ipv4.udp_mem=16777216 16777216 16777216

# Оптимизация для Btrfs и SSD
vm.dirty_background_bytes=134217728  # 128 МБ (для NVMe)
vm.dirty_bytes=536870912 # 512MB
EOF
   check_success "создание конфигурации sysctl"

   log_success "Параметры ядра успешно настроены"
}

# 5. Функция для настройки переменных окружения (NVIDIA)
configure_wayland() {
   log_message "Настройка переменных окружения..."

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
   check_success "настройка переменных окружения"

   log_success "Настройка переменных окружения успешно настроена"
}

# 6. Функция для настройки Plex Media Server
configure_plex() {
   log_message "Настройка Plex Media Server..."

   # Устанавливаем владельца над папкой
   chown -R plex:plex /media
   check_success "установка прав владельца для папки /media"

   # Добавляем права самой родительской папке
   chmod -R 775 /media
   check_success "установка прав доступа для папки /media"

   # Настраиваем службу
   systemctl enable plexmediaserver.service
   check_success "включение службы Plex Media Server"

   systemctl start plexmediaserver.service
   check_success "запуск службы Plex Media Server"

   log_success "Plex Media Server успешно настроен"
}

# 7. Функция для установки и настройки системных служб
configure_system_services() {
   log_message "Настройка системных служб и демонов..."

   systemctl daemon-reload
   check_success "перезагрузка конфигурации systemd"

   # Настройка zram
   log_message "Cоздание конфигурации zram..."
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
   check_success "создание конфигурации zram"

   # Настройка службы v2raya
   log_message "Cоздание конфигурации службы v2raya..."
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
   check_success "создание конфигурации службы v2raya"

   # Включение и запуск системных служб
   log_message "Включение системных служб..."
   systemctl enable paccache.timer systemd-zram-setup@zram0.service bluetooth.service v2raya.service power-profiles-daemon thermald systemd-oomd cronie.service
   check_success "включение служб"

   log_message "Запуск системных служб..."
   systemctl start systemd-zram-setup@zram0.service bluetooth.service v2raya.service
   check_success "запуск служб"

   # Настройка еженедельной очистки кэша pacman
   # Удаляем таймер, если он существует
   if systemctl status pacman-cleaner.timer &>/dev/null; then
      log_message "Удаление существующего таймера pacman-cleaner.timer..."
      systemctl stop pacman-cleaner.timer
      systemctl disable pacman-cleaner.timer
      rm -f /etc/systemd/system/pacman-cleaner.timer
      systemctl daemon-reload
   fi

   # Создаем новый таймер
   log_message "Создание таймера очистки кэша pacman..."
   systemd-run --on-calendar="Sun 10:00" --unit="pacman-cleaner" /sbin/pacman -Scc
   check_success "настройка еженедельной очистки кэша pacman"

   # Перезагрузка конфигурации systemd
   log_message "Перезагрузка конфигурации systemd..."
   systemctl daemon-reload
   check_success "перезагрузка конфигурации systemd"

   log_success "Системные службы и демоны успешно настроены"
}

# 8. Функция для настройки NVIDIA
configure_nvidia() {
   if ! $NVIDIA_PRESENT; then
      log_message "Видеокарта NVIDIA не обнаружена. Пропуск настройки NVIDIA."
      return 0
   fi

   log_message "Настройка NVIDIA..."

   # Включение envycontrol в режиме NVIDIA
   log_message "Включение envycontrol в режиме NVIDIA..."
   envycontrol -s nvidia --force-comp
   check_success "включение envycontrol в режиме NVIDIA"

   # Правка конфига nvidia.conf
   log_message "Настройка конфигурации NVIDIA..."
   rm -f /etc/modprobe.d/nvidia.conf
   check_success "удаление старого конфига nvidia.conf"

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
   check_success "создание нового конфига nvidia.conf"

   # Включение служб NVIDIA
   systemctl enable nvidia-resume nvidia-suspend nvidia-hibernate
   check_success "включение служб NVIDIA"

   # Перезагрузка конфигурации systemd
   log_message "Перезагрузка конфигурации systemd..."
   systemctl daemon-reload
   check_success "перезагрузка конфигурации systemd"

   log_success "NVIDIA успешно настроена"
}

# 9. Функция для замены bash на zsh
change_shell_to_zsh() {
   log_message "Замена bash на zsh..."

   chsh -s $(which zsh)
   check_success "замена оболочки на zsh"

   log_success "Оболочка успешно изменена на zsh"
}

# Основная функция
main() {
   log_message "Начало процесса оптимизации и настройки Arch Linux (Часть 3)..."

   # Вывод информации о наличии NVIDIA
   if $NVIDIA_PRESENT; then
      log_message "Обнаружена видеокарта NVIDIA. Будут применены соответствующие настройки."
   else
      log_message "Видеокарта NVIDIA не обнаружена. Настройки NVIDIA будут пропущены."
   fi

   configure_initramfs
   increase_system_limits
   configure_bootloader
   configure_sysctl
   configure_wayland
   configure_plex
   configure_system_services
   configure_nvidia
   change_shell_to_zsh

   log_message "Все операции успешно завершены!"
   log_success "===== КОНЕЦ 3-ей ЧАСТИ ====="
}

# Запуск основной функции
main
