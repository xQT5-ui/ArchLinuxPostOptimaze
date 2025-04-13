#!/bin/bash

# =====================================================
# Скрипт для установки AUR-пакетов и настройки системы. Часть 2
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

# Проверка, что скрипт не запущен от имени root
if [[ $EUID -eq 0 ]]; then
    log_error "Этот скрипт НЕ должен быть запущен с правами суперпользователя"
    echo "Используйте: $0 без sudo"
    exit 1
fi

# 1. Функция для установки yay
install_yay() {
    log_message "Установка yay..."

    cd ~
    git clone https://aur.archlinux.org/yay.git
    check_success "клонирование репозитория yay"

    cd ~/yay
    makepkg -si --noconfirm
    check_success "сборка и установка yay"

    cd ~
    rm -rf ~/yay

    log_success "yay успешно установлен"
}

# 2. Функция для проверки и установки yay
setup_yay() {
    # Проверяем, установлен ли уже yay
    if command -v yay &> /dev/null; then
        log_message "yay уже установлен"
    else
        log_message "yay не установлен. Начинаем установку..."
        install_yay
    fi

    # Проверяем, успешно ли установился yay
    if command -v yay &> /dev/null; then
        # Обновляем PATH для текущей сессии
        export PATH="$PATH:~/.local/bin"

        # Добавляем PATH в .bashrc для будущих сессий, если его там еще нет
        if ! grep -q 'export PATH="$PATH:~/.local/bin"' ~/.bashrc; then
            echo 'export PATH="$PATH:~/.local/bin"' >> ~/.bashrc
            log_message "PATH обновлен в .bashrc"
        fi
    else
        log_error "Не удалось установить yay. Пожалуйста, проверьте ошибки выше"
        exit 1
    fi
}

# функция для установки пакета с повторными попытками
install_package() {
    local package=$1
    local max_attempts=3
    local attempt=1

    log_message "Установка пакета: $package"

    while [ $attempt -le $max_attempts ]; do
        if yay -S --noconfirm "$package"; then
            log_success "Пакет $package успешно установлен"
            return 0
        else
            log_error "Попытка $attempt из $max_attempts для установки $package не удалась. Повтор через 5 секунд..."
            sleep 5
            ((attempt++))
        fi
    done

    log_error "Не удалось установить пакет $package после $max_attempts попыток"
    return 1
}

# 3. Функция для установки AUR-пакетов
install_aur_packages() {
    log_message "Установка пакетов из AUR..."

    # Обновляем кэш
    yay -Sy
    check_success "обновление кэша yay"

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
        "nautilus-open-any-terminal"
        "visual-studio-code-bin"
        "v2raya"
        "ttf-ms-fonts"
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
        log_error "Следующие пакеты не удалось установить:"
        for package in "${failed_packages[@]}"; do
            echo "  - $package"
        done
    else
        log_success "Все пакеты из AUR успешно установлены"
    fi
}

# 4. Функция для настройки makepkg.conf
configure_makepkg() {
    log_message "Настройка makepkg.conf..."

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
    check_success "создание конфигурации makepkg"

    log_success "makepkg.conf успешно настроен"
}

# 5. Функция для создания дополнительных папок
create_directories() {
    log_message "Создание дополнительных папок..."

    mkdir -p ~/.themes
    mkdir -p ~/.icons
    mkdir -p ~/Загрузки/Torrents
    check_success "создание пользовательских директорий"

    # Эти директории требуют sudo, поэтому обрабатываем их отдельно
    if sudo mkdir -p /media/movies /media/tvshows; then
        log_success "Директории для медиа созданы"

        # Создаем символические ссылки
        ln -sf /media/movies ~/Загрузки/Torrents
        ln -sf /media/tvshows ~/Загрузки/Torrents
        check_success "создание символических ссылок"
    else
        log_error "Не удалось создать директории для медиа. Требуются права sudo"
    fi

    log_success "Дополнительные папки успешно созданы"
}

# 6. Функция для настройки полномочий пользователя
configure_user_permissions() {
    log_message "Настройка полномочий пользователя..."

    if sudo usermod -a -G video,realtime,audio $USER; then
        log_success "Пользователь $USER добавлен в группы video, realtime и audio"
    else
        log_error "Не удалось добавить пользователя в группы. Требуются права sudo"
    fi

    if sudo gpasswd -a $USER plex && sudo gpasswd -a $USER power; then
        log_success "Пользователь $USER добавлен в группы plex и power"
    else
        log_error "Не удалось добавить пользователя в группы plex и power. Требуются права sudo"
    fi

    # Устанавливаем правильные права на файлы ZSH
    touch ~/.zshrc ~/.zsh_history
    chown $USER:$USER ~/.zshrc ~/.zsh_history
    check_success "установка прав на файлы ZSH"

    log_success "Полномочия пользователя успешно настроены"
}

# Основная функция
main() {
   log_message "Начало процесса установки AUR-пакетов и настройки системы (Часть 2)..."

   setup_yay
   configure_makepkg
   install_aur_packages
   create_directories
   configure_user_permissions

   log_message "Все операции успешно завершены!"
   log_success "===== КОНЕЦ 2-ой ЧАСТИ ====="
}

# Запуск основной функции
main
