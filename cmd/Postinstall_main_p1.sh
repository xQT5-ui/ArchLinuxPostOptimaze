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

# 2. Функция для установки базового ПО
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

# 3. Функция для оптимизации GNOME
optimize_gnome() {
   log_message "Оптимизация GNOME путем удаления ненужных пакетов..."

   pacman -Rnsc --noconfirm gnome-connections gnome-music gnome-maps totem gnome-contacts gnome-system-monitor gnome-tour gnome-weather loupe epiphany yelp decibels vim malcontent
   check_success "удаление ненужных пакетов GNOME"

   log_success "GNOME успешно оптимизирован"
}

# 4. Функция для установки Flatpak-приложений
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
   install_base_software
   optimize_gnome
   install_flatpak_apps

   log_message "Все операции успешно завершены!"
   log_success "===== Конец 1-ой части ====="
}

# Запуск основной функции
main