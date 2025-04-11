#!/bin/bash

# Проверка наличия прав суперпользователя
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт должен быть запущен с правами суперпользователя" 
   exit 1
fi

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
