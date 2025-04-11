#!/bin/bash

# 15. Установка AUR-пакетов [это нельзя запускать под sudo!!!]
# Установка yay (если не установлен)
echo "Установка yay..."

install_yay() {
    cd ~
    git clone https://aur.archlinux.org/yay.git
    cd yay
    # Запускаем makepkg без sudo, так как скрипт уже выполняется от имени пользователя
    makepkg -si --noconfirm
    cd ~
    rm -rf yay
}

# Проверяем, установлен ли уже yay
if command -v yay &> /dev/null; then
    echo "yay уже установлен."
else
    echo "yay не установлен. Начинаем установку..."
    install_yay
fi

# Проверяем, успешно ли установился yay
if command -v yay &> /dev/null; then
    echo "yay успешно установлен."
    
    # Обновляем PATH для текущей сессии
    export PATH="$PATH:~/.local/bin"
    
    # Добавляем PATH в .bashrc для будущих сессий
    echo 'export PATH="$PATH:~/.local/bin"' >> "~/.bashrc"
else
    echo "Не удалось установить yay. Пожалуйста, проверьте ошибки выше."
    exit 1
fi

echo "Установка yay... --> DONE"

echo "Установка пакетов из AUR..."
# обновляем кэш
yay -Sy

install_package() {
    local package=$1
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if yay -S --noconfirm "$package"; then
            echo "Пакет $package успешно установлен."
            return 0
        else
            echo "Попытка $attempt из $max_attempts для установки $package не удалась. Повтор через 5 секунд..."
            sleep 5
            ((attempt++))
        fi
    done

    echo "Не удалось установить пакет $package после $max_attempts попыток."
    return 1
}

# Список пакетов для установки
packages=(
    "pamac-flatpak" "envycontrol" "zsh-theme-powerlevel10k" "xcursor-simp1e-adw-dark" 
    "adw-gtk-theme" "ventoy-bin" "plex-media-server" "cachyos-ananicy-rules-git" 
    "ananicy-cpp" "nautilus-admin-gtk4" 
    "nautilus-open-any-terminal" "visual-studio-code-bin" "v2raya" "ttf-ms-fonts"
)

# Установка пакетов
for package in "${packages[@]}"; do
    install_package "$package"
done

echo "Установка пакетов из AUR... --> DONE"

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

# 2. Настройка makepkg.conf
echo "Настройка makepkg.conf..."

cat << EOF > ~/.makepkg.conf
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
# ==> ОШИБКА: Cannot find the ccache binary required for compiler cache usage.
BUILDENV=(!distcc color !ccache check !sign)

# Сжатие пакетов
COMPRESSZST=(zstd -c -z -q -T0 -22 -)
COMPRESSXZ=(xz -c -z --threads=0 -)

# Использование tmpfs для сборки (если достаточно RAM)
BUILDDIR=/tmp/makepkg

# Отключение дебаг-символов для уменьшения размера пакетов
OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug lto)
EOF

echo "Настройка makepkg.conf... --> DONE"

# 21. Создание дополнительный папок
echo "Создание дополнительный папок..."

mkdir -p ~/.themes
mkdir -p ~/.icons
mkdir -p ~/Загрузки/Torrents
mkdir -p /media/movies
mkdir -p /media/tvshows
ln -s /media/movies ~/Загрузки/Torrents
ln -s /media/tvshows ~/Загрузки/Torrents

echo "Создание дополнительный папок... --> DONE"

# Работа с полномочиями
sudo usermod -a -G video $USER
sudo usermod -aG realtime $USER
sudo usermod -aG audio $USER
# Даём доступ для текущего пользователя к доступу и использованию папки для plex
sudo gpasswd -a $USER plex
sudo gpasswd -a $USER power	
sudo chown $USER:$USER ~/.zshrc ~/.zsh_history

echo "===== Конец 2-ой части ====="
