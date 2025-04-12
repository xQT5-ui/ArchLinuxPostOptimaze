#!/bin/bash

# Проверка наличия прав суперпользователя
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт должен быть запущен с правами суперпользователя" 
   exit 1
fi

# 1. Правка конфига pacman.conf
echo "Правка конфига pacman.conf..."

# Раскомментирование и установка Color и ParallelDownloads
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
# Вставка новых строк после ParallelDownloads = 5
sed -i '/^ParallelDownloads = 5/a ILoveCandy\nDisableDownloadTimeout' /etc/pacman.conf

echo "Правка конфига pacman.conf... --> DONE"

# 3. Оптимизации Btrfs
echo "Оптимизация параметров монтирования Btrfs..."

# Замена опций монтирования для всех разделов Btrfs [работает но добавляет строку к текущему без замены]
# sed -i 's/btrfs/btrfs     rw,noatime,compress=zstd:1,ssd,space_cache=v2,discard=async,autodefrag,commit=120/' /etc/fstab
cp ./fstab /etc/fstab

echo "Оптимизация параметров монтирования Btrfs... --> DONE"

# 4. Добавление важных модулей в образы initramfs
echo "Добавление важных модулей в образы initramfs..."

echo "MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm btrfs)" > /etc/mkinitcpio.conf.d/10-modules.conf

echo "Добавление важных модулей в образы initramfs... --> DONE"

# 5. Ускорение загрузки системы c помощью systemd
echo "Ускорение загрузки системы c помощью systemd..."

sed -i 's/HOOKS=.*/HOOKS=(systemd autodetect modconf microcode kms keyboard keymap sd-vconsole block filesystems)/' /etc/mkinitcpio.conf

echo "Ускорение загрузки системы c помощью systemd... --> DONE"

# 6. Повышение лимитов
echo "Повышение лимитов..."

sed -i 's/.*DefaultLimitNOFILE=.*/DefaultLimitNOFILE=1046576/' /etc/systemd/system.conf
sed -i 's/.*DefaultLimitNOFILE=.*/DefaultLimitNOFILE=1046576/' /etc/systemd/user.conf
sed -i '/#@student        -       maxlogins       4/a '"$SUDO_USER"' hard nofile 1046576' /etc/security/limits.conf

echo "Повышение лимитов... --> DONE"

# 7. Обновление загрузчика и отключение ненужных заплаток
echo "Обновление загрузчика и отключение ненужных заплаток..."

sed -i 's/^GRUB_TIMEOUT=[0-9]\+/GRUB_TIMEOUT=1/' /etc/default/grub
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia-drm.modeset=1 modprobe.blacklist=nouveau zswap.enabled=0 tsc=reliable threadirqs"/' /etc/default/grub
sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=countdown/' /etc/default/grub

echo "Обновление загрузчика и отключение ненужных заплаток... --> DONE"

# 8. Установка базового ПО
# исключить так как уже есть после archinstall: base-devel nano unzip gvfs gvfs-mtp flatpak intel-ucode mesa vulkan-icd-loader nvidia-utils btrfs-progs pipewire pipewire-jack pipewire-pulse gst-plugin-pipewire alsa-lib alsa-card-profiles wireplumber firefox gimp
echo "Установка базового ПО..."

pacman -Syyuu --noconfirm
pacman -S --noconfirm neofetch lrzip unrar unzip unace p7zip squashfs-tools gvfs gvfs-mtp flatpak zsh zsh-autosuggestions zsh-completions zsh-history-substring-search zsh-syntax-highlighting intel-ucode mesa vulkan-intel vulkan-icd-loader lib32-pipewire-jack xorg-xrandr go gufw nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader lib32-opencl-nvidia opencl-nvidia libxnvctrl libva-nvidia-driver lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader realtime-privileges btrfs-progs gdu duf wireguard-tools power-profile-daemon pipewire pipewire-jack lib32-pipewire gst-plugin-pipewire alsa-lib alsa-utils alsa-firmware alsa-card-profiles alsa-plugins pipewire-pulse wireplumber pacman-contrib timeshift aspell aspell-en aspell-ru noto-fonts-cjk inxi v2ray thermald bluez-utils exfat-utils reflector rsync file-roller zram-generator papirus-icon-theme steam mangohud libva-nvidia-driver libvdpau-va-gl

echo "Установка базового ПО... --> DONE"

# 9. Настройка /etc/sysctl.d/
echo "Настройка /etc/sysctl.d/..."

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

echo "Настройка /etc/sysctl.d/... --> DONE"

# 10. Удаление ненужных пакетов
pacman -Rnsc --noconfirm gnome-connections gnome-music gnome-software gnome-maps totem gnome-contacts gnome-system-monitor gnome-tour gnome-weather loupe epiphany yelp

echo "Оптимизация GNOME... --> DONE"

# 11. Установка Flatpak-ПО
echo "Установка Flatpak-ПО..."

flatpak install --noninteractive flathub com.bitwig.BitwigStudio com.discordapp.Discord com.github.johnfactotum.Foliate com.github.finefindus.eyedropper io.bassi.Amberol com.github.tchx84.Flatseal com.mattjakeman.ExtensionManager com.transmissionbt.Transmission com.usebottles.bottles com.vysp3r.ProtonPlus io.github.celluloid_player.Celluloid io.github.flattool.Warehouse io.github.jliljebl.Flowblade io.github.seadve.Mousai io.github.tntwise.REAL-Video-Enhancer org.gnome.Mines org.gnome.Quadrapassel org.gnome.Reversi org.nickvision.tagger org.nickvision.tubeconverter org.onlyoffice.desktopeditors org.telegram.desktop org.torproject.torbrowser-launcher org.gtk.Gtk3theme.adw-gtk3-dark org.nickvision.cavalier com.obsproject.Studio net.nokyan.Resources org.gimp.GIMP org.gnome.Calculator org.gnome.Evince org.gnome.Loupe org.gnome.SoundRecorder org.soundconverter.SoundConverter org.pipewire.Helvum app.zen_browser.zen com.jgraph.drawio.desktop io.github.amit9838.mousam
flatpak repair
flatpak update -y
flatpak remove --unused -y

echo "Установка Flatpak-ПО... --> DONE"

# 12 Настройка доступности Wayland сессии
echo "Настройка доступности Wayland-сессии..."
# дополнение /etc/environment
echo '# Основные настройки NVIDIA для Wayland
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
# GSK_RENDERER=cairo' >> /etc/environment

# дополнение /etc/gdm/constom.conf
sed -i '/#WaylandEnable=false/a #DefaultSession=gnome-xorg.desktop #gnome.desktop gnome-xorg.desktop' /etc/gdm/custom.conf

echo "Настройка доступности Wayland-сессии... --> DONE"

echo "===== Конец 1-ой части ====="

