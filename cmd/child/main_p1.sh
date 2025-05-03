#!/bin/bash

# =====================================================
# Скрипт для оптимизации и настройки Arch Linux. Часть 1
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

# 1. Функция для настройки pacman.conf
configure_pacman() {
   log_message "Configuring the pacman.conf configuration..."

   # Раскомментирование и установка Color и ParallelDownloads
   sed -i 's/#Color/Color/' /etc/pacman.conf
   check_success "enabling color output in pacman"

   sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
   check_success "configuring parallel downloads"

   # Вставка новых строк после ParallelDownloads = 5
   sed -i '/^ParallelDownloads = 5/a ILoveCandy\nDisableDownloadTimeout' /etc/pacman.conf
   check_success "adding additional pacman options"

   log_success "The pacman.conf configuration has been successfully updated"
}

# 2. Функция для установки базового ПО
# исключить так как уже есть после archinstall: base-devel unzip gvfs gvfs-mtp flatpak mesa vulkan-icd-loader nvidia-utils btrfs-progs pipewire pipewire-jack pipewire-pulse gst-plugin-pipewire alsa-lib alsa-card-profiles wireplumber firefox gimp
install_base_software() {
   log_message "Installing the basic software..."

   log_message "Updating the system..."
   pacman -Syyuu --noconfirm
   check_success "updating the system"

   log_message "Installing packages..."
   pacman -S --noconfirm git neofetch lrzip unrar unace p7zip squashfs-tools zsh zsh-autosuggestions zsh-completions zsh-history-substring-search zsh-syntax-highlighting lib32-pipewire-jack xorg-xrandr go gufw lib32-vulkan-icd-loader lib32-mesa realtime-privileges gdu duf wireguard-tools power-profiles-daemon lib32-pipewire alsa-utils pacman-contrib timeshift inxi v2ray thermald bluez-utils exfat-utils file-roller zram-generator papirus-icon-theme
   # Блок для Intel + NVIDIA или другого оборудования
   if $NVIDIA_PRESENT; then
      pacman -S --noconfirm libva-nvidia-driver nvidia-utils lib32-nvidia-utils nvidia-settings lib32-opencl-nvidia opencl-nvidia libvdpau-va-gl libvdpau libxnvctrl
   fi
   pacman -S --noconfirm intel-ucode lib32-vulkan-intel
   check_success "installing packages"

   log_success "The basic software has been successfully installed"
}

# 3. Функция для оптимизации GNOME
optimize_gnome() {
   log_message "Optimize GNOME by removing unnecessary packages..."

   pacman -Rnsc --noconfirm gnome-connections gnome-software gnome-music gnome-maps totem gnome-contacts gnome-system-monitor gnome-tour gnome-weather loupe epiphany yelp decibels vim malcontent
   check_success "removing unnecessary GNOME packages"

   log_message "Installing additional 'flatpak' packages..."

   pacman -S --noconfirm flatpak
   check_success "installing 'flatpak'"

   log_success "GNOME has been successfully optimized"
}

# 4. Функция для установки Flatpak-приложений
install_flatpak_apps() {
   log_message "Installing Flatpak-applications..."

   flatpak install --noninteractive flathub
   flatpak install --noninteractive com.bitwig.BitwigStudio com.discordapp.Discord com.github.johnfactotum.Foliate com.github.finefindus.eyedropper io.bassi.Amberol com.github.tchx84.Flatseal com.mattjakeman.ExtensionManager com.transmissionbt.Transmission com.usebottles.bottles com.vysp3r.ProtonPlus io.github.celluloid_player.Celluloid io.github.flattool.Warehouse io.github.jliljebl.Flowblade io.github.seadve.Mousai io.github.tntwise.REAL-Video-Enhancer org.gnome.Mines org.gnome.Quadrapassel org.gnome.Reversi org.nickvision.tagger org.nickvision.tubeconverter org.onlyoffice.desktopeditors org.telegram.desktop org.torproject.torbrowser-launcher org.gtk.Gtk3theme.adw-gtk3-dark org.nickvision.cavalier com.obsproject.Studio net.nokyan.Resources com.github.PintaProject.Pinta org.gnome.Calculator org.gnome.Evince org.gnome.Loupe org.gnome.SoundRecorder org.soundconverter.SoundConverter org.pipewire.Helvum app.zen_browser.zen com.jgraph.drawio.desktop io.github.amit9838.mousam com.github.wwmm.easyeffects io.github.radiolamp.mangojuice com.valvesoftware.Steam org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08
   check_success "installing Flatpak-applications"

   log_message "Flatpack recovery and update..."
   flatpak repair
   check_success "flatpack recovery and update"

   flatpak update -y
   check_success "flatpak update"

   flatpak remove --unused -y
   check_success "removing unused Flatpak components"

   log_success "Flatpak-applications have been successfully installed and configured"
}

# Основная функция
main() {
   log_message "The beginning of the Arch Linux optimization and configuration process (Part 1)..."

   # Вывод информации о наличии NVIDIA
   if $NVIDIA_PRESENT; then
      log_message "An NVIDIA graphics card has been detected. The appropriate settings will be applied."
   else
      log_message "No NVIDIA graphics card detected. NVIDIA settings will be skipped."
   fi

   configure_pacman
   install_base_software
   optimize_gnome
   install_flatpak_apps

   log_message "All operations have been completed successfully!"
   log_success "===== END OF THE 1ST PART ====="
}

# Запуск основной функции
main