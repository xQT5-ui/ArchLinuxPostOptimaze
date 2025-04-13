#!/bin/bash

# =====================================================
# Скрипт для оптимизации и настройки Arch Linux. Часть 1
# =====================================================

# Включаем строгий режим для bash
set -e  # Скрипт завершится при любой ошибке
set -u  # Использование неопределенных переменных вызовет ошибку

# Функция для вывода сообщений
log_message() {
   echo -e "\e[1;34m[INFO] $1\e[0m"
}

# Функция для вывода сообщений об ошибках
log_error() {
   echo -e "\e[1;31m[ERROR] $1\e[0m" >&2
}

# Функция для вывода сообщений об успешном выполнении
log_success() {
   echo -e "\e[1;32m[SUCCESS] $1\e[0m"
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

# 1. Функция для настройки pacman.conf
configure_pacman() {
   log_message "Настройка конфигурации pacman.conf..."

   # Раскомментирование и установка Color и ParallelDownloads
   sed -i 's/#Color/Color/' /etc/pacman.conf
   check_success "включение цветного вывода в pacman"

   sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
   check_success "настройка параллельных загрузок"

   # Вставка новых строк после ParallelDownloads = 5
   sed -i '/^ParallelDownloads = 5/a ILoveCandy\nDisableDownloadTimeout' /etc/pacman.conf
   check_success "добавление дополнительных опций pacman"

   log_success "Конфигурация pacman.conf успешно обновлена"
}

# 2. Функция для настройки initramfs
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

# 3. Функция для повышения системных лимитов
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

# 4. Функция для настройки загрузчика GRUB
configure_bootloader() {
   log_message "Настройка загрузчика GRUB..."

   sed -i 's/^GRUB_TIMEOUT=[0-9]\+/GRUB_TIMEOUT=1/' /etc/default/grub
   check_success "настройка таймаута GRUB"

   if $NVIDIA_PRESENT; then
      sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia-drm.modeset=1 modprobe.blacklist=nouveau zswap.enabled=0 tsc=reliable threadirqs"/' /etc/default/grub
   else
      sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash zswap.enabled=0 tsc=reliable threadirqs"/' /etc/default/grub
   fi
   check_success "настройка параметров ядра"

   sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=countdown/' /etc/default/grub
   check_success "настройка стиля таймаута GRUB"

   log_success "Загрузчик GRUB успешно настроен"
}

# 5. Функция для установки базового ПО
# исключить так как уже есть после archinstall: base-devel unzip gvfs gvfs-mtp flatpak mesa vulkan-icd-loader nvidia-utils btrfs-progs pipewire pipewire-jack pipewire-pulse gst-plugin-pipewire alsa-lib alsa-card-profiles wireplumber firefox gimp
install_base_software() {
   log_message "Установка базового программного обеспечения..."

   log_message "Обновление системы..."
   pacman -Syyuu --noconfirm
   check_success "обновление системы"

   log_message "Установка базовых пакетов..."
   pacman -S --noconfirm neofetch lrzip unrar unace p7zip squashfs-tools zsh zsh-autosuggestions zsh-completions zsh-history-substring-search zsh-syntax-highlighting lib32-pipewire-jack xorg-xrandr go gufw lib32-vulkan-icd-loader lib32-mesa realtime-privileges gdu duf wireguard-tools power-profiles-daemon lib32-pipewire alsa-utils pacman-contrib timeshift inxi v2ray thermald bluez-utils exfat-utils file-roller zram-generator papirus-icon-theme steam mangohud
   # Блок для Intel + NVIDIA или другого оборудования
   if $NVIDIA_PRESENT; then
      pacman -S --noconfirm libva-nvidia-driver nvidia-utils lib32-nvidia-utils nvidia-settings lib32-opencl-nvidia opencl-nvidia libvdpau-va-gl libvdpau libxnvctrl
   fi
   pacman -S --noconfirm intel-ucode lib32-vulkan-intel
   check_success "установка базовых пакетов"

   log_success "Базовое программное обеспечение успешно установлено"
}

# 6. Функция для настройки параметров ядра
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

# 7. Функция для оптимизации GNOME
optimize_gnome() {
   log_message "Оптимизация GNOME путем удаления ненужных пакетов..."

   pacman -Rnsc --noconfirm gnome-connections gnome-music gnome-maps totem gnome-contacts gnome-system-monitor gnome-tour gnome-weather loupe epiphany yelp decibels vim malcontent
   check_success "удаление ненужных пакетов GNOME"

   log_success "GNOME успешно оптимизирован"
}

echo "Оптимизация GNOME... --> DONE"

# 8. Функция для установки Flatpak-приложений
install_flatpak_apps() {
   log_message "Установка Flatpak-приложений..."

   flatpak install --noninteractive flathub
   flatpak install --noninteractive com.bitwig.BitwigStudio com.discordapp.Discord com.github.johnfactotum.Foliate com.github.finefindus.eyedropper io.bassi.Amberol com.github.tchx84.Flatseal com.mattjakeman.ExtensionManager com.transmissionbt.Transmission com.usebottles.bottles com.vysp3r.ProtonPlus io.github.celluloid_player.Celluloid io.github.flattool.Warehouse io.github.jliljebl.Flowblade io.github.seadve.Mousai io.github.tntwise.REAL-Video-Enhancer org.gnome.Mines org.gnome.Quadrapassel org.gnome.Reversi org.nickvision.tagger org.nickvision.tubeconverter org.onlyoffice.desktopeditors org.telegram.desktop org.torproject.torbrowser-launcher org.gtk.Gtk3theme.adw-gtk3-dark org.nickvision.cavalier com.obsproject.Studio net.nokyan.Resources org.gimp.GIMP org.gnome.Calculator org.gnome.Evince org.gnome.Loupe org.gnome.SoundRecorder org.soundconverter.SoundConverter org.pipewire.Helvum app.zen_browser.zen com.jgraph.drawio.desktop io.github.amit9838.mousam
   check_success "установка Flatpak-приложений"

   log_message "Восстановление и обновление Flatpak..."
   flatpak repair
   check_success "восстановление Flatpak"

   flatpak update -y
   check_success "обновление Flatpak"

   flatpak remove --unused -y
   check_success "удаление неиспользуемых Flatpak-компонентов"

   log_success "Flatpak-приложения успешно установлены и настроены"
}

# 9. Функция для настройки переменных окружения (NVIDIA)
configure_wayland() {
   log_message "Настройка поддержки Wayland..."

   # Дополнение /etc/environment
   if $NVIDIA_PRESENT; then
      cat << EOF >> /etc/environment
# Основные настройки NVIDIA для Wayland
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
LIBVA_DRIVER_NAME=nvidia
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
   check_success "настройка переменных окружения для Wayland"

   log_success "Поддержка Wayland успешно настроена"
}

# Основная функция
main() {
   log_message "Начало процесса оптимизации и настройки Arch Linux (Часть 1)..."

   # Вывод информации о наличии NVIDIA
   if $NVIDIA_PRESENT; then
      log_message "Обнаружена видеокарта NVIDIA. Будут применены соответствующие настройки."
   else
      log_message "Видеокарта NVIDIA не обнаружена. Настройки NVIDIA будут пропущены."
   fi

   configure_pacman
   configure_initramfs
   increase_system_limits
   configure_bootloader
   install_base_software
   configure_sysctl
   optimize_gnome
   install_flatpak_apps
   configure_wayland

   log_message "Все операции успешно завершены!"
   log_success "===== Конец 1-ой части ====="
}

# Запуск основной функции
main