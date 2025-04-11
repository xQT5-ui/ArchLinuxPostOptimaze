# Установка Arch Linux

# Правила выбора пакетов приложений
- все системные приложения (для DE по работе с дисками, текстовый редактор для изменения корневых файлов, эмулятор терминала и т.д.) = только нативные пакеты
- все графические приложения:
    1. Если разработчик официально поддерживает Flatpak - ставим его, потому что добавляет больше стабильности, изолированности, универсальности и устранения проблем с зависимостями. В современных системах просадки производительности из-за прокси-слоёв незначительны
    2. Если разработчик официально не поддерживает Flatpak - ставим натив/AUR
    3. Если у Flatpak наблюдаются проблемы - переходим на натив

## Образ и его установка
1. Скачиваем официальный образ (iso) с сайта [Arch Linux](https://archlinux.org/download/)
2. Монтировать образ на флешку:
    - Windows: утилита 'Rufus' с режимом FAT32
    - Linux: утилита 'Ventoy'
3. Запускаем флешку через БИОС
4. По инструкции при использовании Wi-Fi необходимо вручную подключиться к сети через команду `iwctl`:
    ```bash
    iwctl
    device list
    station {wlan-name} get-networks
    station {wlan-name} connect {название сети}
    exit
    ping -4 google.com --> должен идти пинг: если идёт то нажимем Ctrl+C
    ```
5. Запускаем `archinstall`
6. Выбираем необходимые параметры по аналогии с графическим установщиком:
    - **Mirrors**: `Russia, Norway, Finland, Switzerland, Germany, Worldwide`
    - **Locales**: `ru`
    - **Bootloader**: `GRUB`
    - **keyboard layout**: `us`
    - **Partitioning**: `Use a best-effort default partition layout` и выбираем нужный диск
    - **Swap**: `False`
    - **Hostname**: `archlinux_...`
    - **Profile**: `Dekstop` -> `GNOME`
    - **Graphics driver**: `Nvidia (proprietary)`
    - **Greeter**: `gdm`
    - **Audio**: `pipewire`
    - **Kernels**: `linux-zen`
    - **Network configuration**: `Use NetworkManager`
    - **Timezone**: `Europe/Moscow`
    - **Automatic time sync**: `True`
    - **Optional repositories**: `multilib`
7. `Install`

## Установка необходимых нативных пакетов
1. создать в домашней папке файл ".zshrc" и заполнить дополнительно:
    source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
> пройтись по https://dev.to/shawon/customize-your-terminal-on-manjaro-using-zsh-with-powerlevel10k-autosuggestion-and-syntax-highlighting-plugin-3692

## Установить расширения для GNOME
- AppIndicator
- Vitals
- Bluetooth Battery Meter
- Blur My Shell
- EasyEffects Preset Selectror
- Dash to Dock
- Gnome 4x UI Improvements
- GPU profile selector
- Just Perfection
- Panel Corners
- User Themes
- Wallpaper Slideshow
- Rounded Window Corners Reborn
- Logo Menu

# Скрипты на установку всего
1. Правка конфига "pamac.conf":
sudo nano /etc/pacman.conf # Раскомментируйте строчку ниже

```bash
# Где 4 - количество пакетов для одновременной загрузки
Color
ParallelDownloads = 5
ILoveCandy
...
[option]
...
DisableDownloadTimeout
```

2. Обновление ключей Arch Linux:
`sudo pacman-key --init && sudo pacman-key --populate archlinux && sudo pacman-key --refresh-keys && sudo pacman -Sy && sudo systemctl enable --now archlinux-keyring-wkd-sync.timer`

- установка таймера на обновление ключей:
`sudo systemctl start archlinux-keyring-wkd-sync.service && sudo systemctl enable --now archlinux-keyring-wkd-sync.timer`

- обновление зеркал (наличие `rsync` и `reflector` обязательно):
`sudo reflector --country 'Germany,Norway,Russia' --latest 21 --protocol https --sort rate --save /etc/pacman.d/mirrorlist`

3. Настройка "makepkg.conf":
Для этого создадим пользовательский конфиг ~/.makepkg.conf в домашней директории, чтобы переопределить системные настройки:
```bash
# Оптимизированный ~/.makepkg.conf

# Используем все доступные ядра процессора
MAKEFLAGS="-j$(nproc)"

# Оптимизации для компилятора
CFLAGS="-march=native -mtune=native -O3 -pipe -fno-plt -fexceptions \
        -Wp,-D_FORTIFY_SOURCE=3 -Wformat -Werror=format-security \
        -fstack-clash-protection -fcf-protection -fuse-ld=gold"
CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"
RUSTFLAGS="-C opt-level=3 -C target-cpu=native -C codegen-units=1 -C link-arg=-z -C link-arg=pack-relative-relocs"

# Оптимизация для линковщика
LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"

# Использование ccache для ускорения повторных сборок
BUILDENV=(!distcc color ccache check !sign)

# Сжатие пакетов
COMPRESSZST=(zstd -c -z -q -T0 -22 -)
COMPRESSXZ=(xz -c -z --threads=0 -)

# Использование tmpfs для сборки (если достаточно RAM)
BUILDDIR=/tmp/makepkg

# Отключение дебаг-символов для уменьшения размера пакетов
OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug lto)
```

4. Оптимизации Btrfs:
`sudo nano /etc/fstab`

- для корневого и домашнего разделов на строчках с `btrfs` пишем рядом:
```bash
.../         	btrfs     	rw,noatime,compress=zstd:3,ssd,ssd_spread,space_cache=v2,discard=async,autodefrag,...
.../home     	btrfs     	rw,noatime,compress=zstd:3,ssd,ssd_spread,space_cache=v2,discard=async,autodefrag,...
.../var/log  	btrfs     	rw,noatime,compress=zstd:1,ssd,space_cache=v2,discard=async,commit=120,...
.../var/cache/pacman/pkg	btrfs     	rw,noatime,compress=zstd:1,ssd,space_cache=v2,discard=async,commit=120,...
.../.snapshots	btrfs     	rw,noatime,compress=zstd:3,ssd,space_cache=v2,discard=async,commit=60,...
```

5. Правка конфига "nvidia.conf":
```bash
sudo nano /etc/modprobe.d/nvidia.conf

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
```

`sudo systemctl enable nvidia-resume nvidia-suspend nvidia-hibernate`

6. Добавление важных модулей в образы initramfs:
нужно создать новый файл со следующим содержанием:
    `sudo nano /etc/mkinitcpio.conf.d/10-modules.conf`
    `MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm btrfs)`

7. Ускорение загрузки системы c помощью systemd:
    `sudo nano /etc/mkinitcpio.conf`
    `HOOKS=(systemd autodetect modconf microcode kms keyboard keymap sd-vconsole block filesystems)`
    
Пояснения:
a) systemd: Оставляем первым, так как это основа для systemd-based initramfs.
b) udev: Добавляем сразу после systemd для раннего обнаружения устройств, что может ускорить загрузку.
c) autodetect: Оставляем для автоматического определения необходимых модулей.
d) microcode: Возвращаем из вашей оригинальной конфигурации, так как это важно для обновлений микрокода процессора.
e) modconf: Перемещаем перед block для правильной загрузки модулей.
f) block: Оставляем для поддержки блочных устройств.
g) keyboard и keymap: Объединяем и располагаем перед filesystems для раннего доступа к клавиатуре.
h) sd-vconsole: Добавляем для более быстрой инициализации виртуальной консоли.
i) filesystems: Оставляем для монтирования файловых систем.

8. Повышение лимитов:
```bash
sudo nano /etc/systemd/system.conf
sudo nano /etc/systemd/user.conf
```
- изменяем `DefaultLimitNOFILE=1046576`
`sudo nano /etc/security/limits.conf`

- (в самый нижний столбец):
`{username} hard nofile 1046576`

11. Обновление загрузчика и отключение ненужных заплаток:
```bash
sudo nano /etc/default/grub
```
- редактируем строку:
    `GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia-drm.modeset=1 modprobe.blacklist=nouveau zswap.enabled=0 tsc=reliable threadirqs"`
    > `intel_idle.max_cstate=1 intel_pstate=active` только для CPU Intel
    > `zswap.enabled=0` только для zram 
    

9. Установка базового ПО:
```bash
sudo pacman -Syyuu && sudo pacman -S --noconfirm base-devel git nano && sudo pacman -S --noconfirm neofetch lrzip unrar unzip unace p7zip squashfs-tools gvfs gvfs-mtp flatpak zsh zsh-autosuggestions zsh-completions zsh-history-substring-search zsh-syntax-highlighting intel-ucode mesa vulkan-intel vulkan-icd-loader lib32-pipewire-jack xorg-xrandr go gufw nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader lib32-opencl-nvidia opencl-nvidia libxnvctrl libva-nvidia-driver lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader realtime-privileges btrfs-progs gdu duf wireguard-tools power-profile-daemon pipewire pipewire-jack lib32-pipewire gst-plugin-pipewire alsa-lib alsa-utils alsa-firmware alsa-card-profiles alsa-plugins pipewire-pulse wireplumber pacman-contrib timeshift aspell aspell-en aspell-ru noto-fonts-cjk inxi v2ray thermald bluez-utils exfat-utils reflector rsync file-roller zram-generator papirus-icon-theme steam mangohud libva-nvidia-driver libvdpau-va-gl
yay -S --noconfirm pamac-flatpak envycontrol zsh-theme-powerlevel10k xcursor-simp1e-adw-dark adw-gtk-theme ventoy-bin plex-media-server visial-studio-code-bin cachyos-ananicy-rules-git ananicy-cpp nautilus-admin-gtk4 nautilus-open-any-terminal mkinitcpio-firmware papirus-folders
yay -S --noconfirm v2raya [настройка здесь https://habr.com/ru/sandbox/191612/]
```
> `yay -S --noconfirm appimagelauncher` - для запуска AppImage-приложений
> `plymouth` - для графического экрана загрузки

`yay -S ttf-ms-fonts` - шрифты от Microsoft

10. Работа с PipeWire:
- добавление себя в группу пользователей "realtime":
`sudo usermod -aG realtime,audio "$USER"`

- создадим пути для хранения конфигурационных файлов в домашней директории:
```bash
mkdir -p ~/.config/pipewire/pipewire.conf.d ~/.config/pipewire/pipewire-pulse.conf.d ~/.config/pipewire/client-rt.conf.d
```

- создадим файл со следующим содержанием:
```bash
nano ~/.config/pipewire/pipewire.conf.d/10-sound.conf

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
```

- добавляем поддержку 5.1:
```bash
cp /usr/share/pipewire/client-rt.conf.avail/20-upmix.conf ~/.config/pipewire/pipewire-pulse.conf.d
cp /usr/share/pipewire/client-rt.conf.avail/20-upmix.conf ~/.config/pipewire/client-rt.conf.d
```
    
- включаем PipeWire если выключен:
```bash
systemctl --user enable --now pipewire pipewire.socket pipewire-pulse wireplumber
```

12. Установка полезных служб и демонов:
    - Автоматическая очистка кэша пакетов:
        ```bash
        sudo systemctl enable paccache.timer
        ```
        
    - Включение службы блютуз:
        ```bash
        sudo systemctl enable bluetooth.service
        sudo systemctl start bluetooth.service
        ```

    - zram-generator:
        создадим файл:
        ```bash
        sudo nano /etc/systemd/zram-generator.conf

        [zram0]
        # Размер zram
        zram-size = min(ram / 2, 8192)
        # Алгоритм сжатия (zstd быстрее lz4 на 5-10%, но требует чуть больше CPU)
        compression-algorithm = zstd
        # Отключить zswap для предотвращения конфликтов
        disable-zswap = true
        # Высший приоритет
        swap-priority = 100
        ```
        
        `sudo systemctl enable systemd-zram-setup@zram0.service`
        `sudo systemctl start systemd-zram-setup@zram0.service`

    - Earlyoom: [по желанию]
        `sudo systemctl enable --now earlyoom`

    - Ananicy CPP: [можно установить но говорят что есть конфликт с планировщиком в linux-zen] [по желанию]
        `sudo systemctl enable --now ananicy-cpp`

    - Автоматическая очистка кэша pacman:
        `sudo systemd-run --on-calendar="Sun 10:00" --unit="pacman-cleaner" /sbin/pacman -Scc`

    - irqbalance: (также пакет называется) [по желанию]
        `sudo systemctl enable --now irqbalance`
        
    - power-profile-daemon (режим производительности для ЦП):
        `sudo systemctl enable --now power-profiles-daemon`
        
    - systemd-oomd: [если система на systemd, то нативнее будет чем earlyoom - но последний работает быстрее]
        `sudo systemctl enable --now systemd-oomd`
        
    - выключаем трекер файлов (увеличит время поиска файлов, но продлит службу носителя памяти):
        `systemctl --user mask localsearch-3.service localsearch-control-3.service localsearch-writeback-3.service`
        
    - v2raya:
        ```bash
        sudo nano /etc/systemd/system/[v2raya].service
        
        вставить текст:
            [Unit]
            Description=Proxy v2rayA Service
            After=network.target

            [Service]
            Type=simple
            ExecStart=/usr/bin/v2raya
            Restart=on-failure

            [Install]
            WantedBy=multi-user.target
            
        sudo systemctl enable [v2raya].service
        sudo systemctl start [v2raya].service
        ```
        
    - thermald = это демон для предотвращения перегрева процессоров Intel. Он мониторит температуру и применяет различные методы охлаждения:
        `sudo systemctl enable --now thermald`

13. Настройка /etc/sysctl.d/:
- создать файл "99-sysctl.conf" и заполнить его:
```bash
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
```

14. Оптимизация GNOME:
- отключаем лишние службы:
    `systemctl --user mask org.gnome.SettingsDaemon.Wacom.service && systemctl --user mask org.gnome.SettingsDaemon.Smartcard.service`

- убираем замыленность шрифтов:
```bash
nano ~/.config/gtk-4.0/settings.ini

# Добавьте ниже к уже имеющимся настройкам
[Settings]
gtk-hint-font-metrics=1
```

- добавляем возможность использования камеры на ноуте (snapshot):
`sudo usermod -a -G video $USER`

15. Установка Flatpak-ПО:
```bash
sudo flatpak install --noninteractive flathub com.bitwig.BitwigStudio com.discordapp.Discord com.github.johnfactotum.Foliate com.github.finefindus.eyedropper io.bassi.Amberol com.github.tchx84.Flatseal com.mattjakeman.ExtensionManager com.transmissionbt.Transmission com.usebottles.bottles com.vysp3r.ProtonPlus io.github.celluloid_player.Celluloid io.github.flattool.Warehouse io.github.jliljebl.Flowblade io.github.seadve.Mousai io.github.tntwise.REAL-Video-Enhancer org.gnome.Mines org.gnome.Quadrapassel org.gnome.Reversi org.nickvision.tagger org.nickvision.tubeconverter org.onlyoffice.desktopeditors org.telegram.desktop org.torproject.torbrowser-launcher org.gtk.Gtk3theme.adw-gtk3-dark org.nickvision.cavalier com.obsproject.Studio net.nokyan.Resources org.gimp.GIMP org.gnome.Calculator org.gnome.Evince org.gnome.Loupe org.gnome.SoundRecorder org.soundconverter.SoundConverter org.pipewire.Helvum app.zen_browser.zen com.jgraph.drawio.desktop io.github.amit9838.mousam && sudo flatpak repair && sudo flatpak update -y
```

16. Настройка ZSH:
1) создать файл `.zshrc` и `.zsh_history` в домашней директории
2) запустить терминал. ввести команду `p10k configure` и пройти настройку
3) наполнить файл `.zshrc` следующим:
```bash
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
```

17. Добавить переменных для файла "/etc/environment":
```md
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
```

!!! Обновляем initramfs и grub-загрузчик:
`sudo mkinitcpio -P && sudo grub-mkconfig -o /boot/grub/grub.cfg`
    
!!! Очистка лишних пакетов и кеша:
`sudo pacman -Scc --noconfirm && sudo pacman -Rscn $(pacman -Qtdq) --noconfirm`
