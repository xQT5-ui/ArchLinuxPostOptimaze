#!/bin/bash

# =====================================================
# Скрипт для установки AUR-пакетов и настройки системы. Часть 2
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

# Проверка, что скрипт не запущен от имени root
if [[ $EUID -eq 0 ]]; then
    log_error "This script should NOT be run with superuser rights"
    echo "Use: $0 without sudo"
    exit 1
fi

# 1. Функция для установки yay
install_yay() {
    log_message "Installing yay..."

    cd ~
    git clone https://aur.archlinux.org/yay.git
    check_success "cloning the yay repository"

    cd ~/yay
    makepkg -si --noconfirm
    check_success "assembling and installing yay"

    cd ~
    rm -rf ~/yay

    log_success "yay has been successfully installed"
}

# 2. Функция для проверки и установки yay
setup_yay() {
    # Проверяем, установлен ли уже yay
    if command -v yay &> /dev/null; then
        log_message "yay is already installed"
    else
        log_message "yay is not installed. Starting the installation..."
        install_yay
    fi

    # Проверяем, успешно ли установился yay
    if command -v yay &> /dev/null; then
        # Обновляем PATH для текущей сессии
        export PATH="$PATH:~/.local/bin"

        # Добавляем PATH в .bashrc для будущих сессий, если его там еще нет
        if ! grep -q 'export PATH="$PATH:~/.local/bin"' ~/.bashrc; then
            echo 'export PATH="$PATH:~/.local/bin"' >> ~/.bashrc
            log_message "PATH updated in ~/.bashrc"
        fi
    else
        log_error "Couldn't install yay. Please check the errors above"
        exit 1
    fi
}

# функция для установки пакета с повторными попытками
install_package() {
    local package=$1
    local max_attempts=3
    local attempt=1

    log_message "Instaling package: $package"

    while [ $attempt -le $max_attempts ]; do
        if yay -S --noconfirm "$package"; then
            log_success "The '$package' package has been successfully installed"
            return 0
        else
            log_error "The $attempt from $max_attempts to install the '$package' failed. Repeat after 5 seconds..."
            sleep 5
            ((attempt++))
        fi
    done

    log_error "Failed to install the '$package' after $max_attempts attempts"
    return 1
}

# 3. Функция для установки AUR-пакетов
install_aur_packages() {
    log_message "Installing packages from AUR..."

    # Обновляем кэш
    yay -Sy
    check_success "updating the yay cache"

    # Список пакетов для установки
    local packages=(
        "pamac-flatpak"
        "envycontrol"
        "zsh-theme-powerlevel10k"
        "xcursor-simp1e-adw-dark"
        "adw-gtk-theme"
        "ventoy-bin"
        "plex-media-server"
        "nautilus-admin-gtk4"
        #"nautilus-open-any-terminal"
        "visual-studio-code-bin"
        "v2raya"
        "ttf-ms-fonts"
        "mkinitcpio-firmware"
        "papirus-folders"
    )

    # Установка пакетов
    local failed_packages=()
    for package in "${packages[@]}"; do
        if ! install_package "$package"; then
            failed_packages+=("$package")
        fi
    done

    # Вывод информации о неудачных установках
    if [ ${#failed_packages[@]} -gt 0 ]; then
        log_error "The following packages could not be installed:"
        for package in "${failed_packages[@]}"; do
            echo "  - $package"
        done
    else
        log_success "All packages from AUR have been successfully installed"
    fi
}

# 4. Функция для настройки makepkg.conf
configure_makepkg() {
    log_message "Setting up makepkg.conf..."

    cat << EOF > ~/.makepkg.conf
# Оптимизированный ~/.makepkg.conf
# Используем все доступные ядра процессора
MAKEFLAGS="-j$(nproc)"

# Оптимизации для компилятора
CFLAGS="-march=native -mtune=native -O3 -pipe -fno-plt -fexceptions \
        -Wp,-D_FORTIFY_SOURCE=3 -Wformat -Werror=format-security \
        -fstack-clash-protection -fcf-protection -fuse-ld=gold"
CXXFLAGS="\$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"
RUSTFLAGS="-C opt-level=3 -C target-cpu=native -C codegen-units=1 -C link-arg=-z -C link-arg=pack-relative-relocs"

# Оптимизация для линковщика
LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"

# Использование ccache для ускорения повторных сборок
BUILDENV=(!distcc color !ccache check !sign)

# Сжатие пакетов
COMPRESSZST=(zstd -c -z -q -T0 -22 -)
COMPRESSXZ=(xz -c -z --threads=0 -)

# Использование tmpfs для сборки (если достаточно RAM)
BUILDDIR=/tmp/makepkg

# Отключение дебаг-символов для уменьшения размера пакетов
OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug lto)
EOF
    check_success "creating the makepkg configuration"

    log_success "makepkg.conf has been successfully configured"
}

# 5. Функция для создания дополнительных папок
create_directories() {
    log_message "Create additional folders..."

    mkdir -p ~/.themes
    mkdir -p ~/.icons
    mkdir -p ~/Загрузки/Torrents
    check_success "creating custom directories"

    # Эти директории требуют sudo, поэтому обрабатываем их отдельно
    if sudo mkdir -p /media/movies /media/tvshows; then
        log_success "Media directories have been created"

        # Создаем символические ссылки
        ln -sf /media/movies ~/Загрузки/Torrents
        ln -sf /media/tvshows ~/Загрузки/Torrents
        check_success "creating symbolic links"
    else
        log_error "Media directories could not be created. Sudo rights are required"
    fi

    log_success "Additional folders have been successfully created"
}

# 6. Функция для настройки полномочий пользователя
configure_user_permissions() {
    log_message "Setting up user permissions..."

    if sudo usermod -a -G video,realtime,audio $USER; then
        log_success "The user $USER has been added to the video, realtime, and audio groups"
    else
        log_error "Couldn't add user to groups. Sudo rights are required"
    fi

    if sudo gpasswd -a $USER plex && sudo gpasswd -a $USER power; then
        log_success "The user $USER has been added to the plex and power groups"
    else
        log_error "Couldn't add user to plex and power groups. Sudo rights are required"
    fi

    # Устанавливаем правильные права на файлы ZSH
    touch ~/.zshrc ~/.zsh_history
    chown $USER:$USER ~/.zshrc ~/.zsh_history
    check_success "setting rights to ZSH files"

    log_success "The user's credentials have been successfully configured"
}

# Основная функция
main() {
   log_message "The beginning of the process of installing AUR packages and configuring the system (Part 2)..."

   setup_yay
   configure_makepkg
   install_aur_packages
   create_directories
   configure_user_permissions

   log_message "All operations have been completed successfully!"
   log_success "===== END OF THE 2ND PART ====="
}

# Запуск основной функции
main
