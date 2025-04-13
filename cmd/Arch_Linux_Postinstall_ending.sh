#!/bin/bash

# Проверка наличия прав суперпользователя
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт должен быть запущен с правами суперпользователя" 
   exit 1
fi

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

# 5. Функция для настройки параметров ядра
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

# 6. Функция для настройки переменных окружения (NVIDIA)
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

# 9. Работа с PipeWire
echo "Работа с PipeWire..."

mkdir -p ~/.config/pipewire/pipewire.conf.d ~/.config/pipewire/pipewire-pulse.conf.d ~/.config/pipewire/client-rt.con

cat << EOF > ~/.config/pipewire/pipewire.conf.d/10-sound.conf
context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 512
    default.clock.min-quantum = 32
    default.clock.max-quantum = 2048
    default.clock.allowed-rates = [ 44100 48000 88200 96000 176400 192000 ]
    default.clock.power-of-two-quantum = true
    support.node.latency = true
}

stream.properties = {
    node.latency = 512/48000
    node.autoconnect = true
    resample.quality = 15
}
EOF

cp /usr/share/pipewire/client-rt.conf.avail/20-upmix.conf ~/.config/pipewire/pipewire-pulse.conf.d
cp /usr/share/pipewire/client-rt.conf.avail/20-upmix.conf ~/.config/pipewire/client-rt.conf.d

echo "Работа с PipeWire... --> DONE"

# 10. Оптимизация GNOME
echo "Оптимизация GNOME..."

mkdir -p ~/.config/gtk-4.0
echo "[Settings]" > ~/.config/gtk-4.0/settings.ini
echo "gtk-hint-font-metrics=1" >> ~/.config/gtk-4.0/settings.ini

# 13. Настройка ZSH
echo "Настройка ZSH..."

touch ~/.zshrc ~/.zsh_history
cat << EOF > ~/.zshrc
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh" ]]; then
  source "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh"
fi

source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# История команд для zsh
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY

# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF

echo "Настройка ZSH... --> DONE"

# 16. Настройка plex media server
echo 'Настройка plex media server...'

# Устанавливаем владельца над папкой
chown -R plex:plex /media

# Добавляем права самой родительской папке
chmod -R 775 /media

# Настраиваем службу
systemctl enable plexmediaserver.service
systemctl start plexmediaserver.service

echo 'Настройка plex media server... --> DONE'

# 17. Установка полезных служб и демонов [запускать строго после AUR!!!]
echo "Установка полезных служб и демонов..."

systemctl daemon-reload

systemctl enable paccache.timer bluetooth.service
systemd-run --on-calendar="Sun 10:00" --unit="pacman-cleaner" /sbin/pacman -Scc

cat << EOF > /etc/systemd/zram-generator.conf
[zram0]
# Размер zram = >50% RAM
zram-size = ram * 0.75
# Алгоритм сжатия (zstd быстрее lz4 на 5-10%, но требует чуть больше CPU)
compression-algorithm = zstd
# Отключить zswap для предотвращения конфликтов
disable-zswap = true
# Высший приоритет
swap-priority = 100
EOF

#rmmod zram
#modprobe zram
systemctl enable systemd-zram-setup@zram0.service bluetooth.service
systemctl start systemd-zram-setup@zram0.service bluetooth.service

systemctl daemon-reload

systemctl enable --now ananicy-cpp power-profiles-daemon thermald systemd-oomd

systemctl daemon-reload

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

systemctl enable v2raya.service
systemctl start v2raya.service

systemctl daemon-reload

systemctl --user enable --now pipewire pipewire.socket pipewire-pulse wireplumber

systemctl --user mask org.gnome.SettingsDaemon.Wacom.service org.gnome.SettingsDaemon.Smartcard.service

echo "Установка полезных служб и демонов... --> DONE"

# 18. Включение envycontrol
echo "Включение envycontrol to NVIDIA mode..."

envycontrol -s nvidia --force-comp

echo "Включение envycontrol to NVIDIA mode... --> DONE"

# 19. Правка конфига nvidia.conf [править лучше после использования envycontrol!!!]
echo "Правка конфига nvidia.conf..."

rm /etc/modprobe.d/nvidia.conf
cat << EOF > /etc/modprobe.d/nvidia.conf
options nvidia NVreg_EnableStreamMemOPs=0
options nvidia NVreg_UseThreadedOptimizations=1
options nvidia NVreg_EnableMSI=1 # Включает Message-Signaled Interrupts для снижения задержек. Актуально для PCIe Gen3+
options nvidia NVreg_UsePageAttributeTable=1 # Улучшает управление памятью через PAT
options nvidia NVreg_PreserveVideoMemoryAllocations=1  # Сохранение видеопамяти при suspend
options nvidia NVreg_EnableGpuFirmware=1  # Аппаратная инициализация для RTX >30xx
options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1" # Приоритет производительности
options nvidia NVreg_EnableHostAllocation=1    # +7% VRAM perf
options nvidia NVreg_EnableResizableBar=1     # PCIe Resizable BAR
options nvidia NVreg_RequireECC=0             # Для не-серверных GPU
EOF

systemctl daemon-reload

systemctl enable nvidia-resume nvidia-suspend nvidia-hibernate

echo "Правка конфига nvidia.conf... --> DONE"

# 20. Замена bash на zsh
echo "Замена bash на zsh..."

chsh -s $(which zsh)

echo "Замена bash на zsh... --> DONE"

echo "===== Конец 3-ей части ====="
