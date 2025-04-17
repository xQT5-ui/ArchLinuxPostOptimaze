
#!/bin/bash

# =====================================================
# Скрипт постустановки и оптимизации системы
# =====================================================

# Цвета для вывода сообщений
BLUE="\e[1;34m"
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
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

# Функция для вывода предупреждений
log_warning() {
   echo -e "${YELLOW}[WARNING] $1${RESET}"
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

# Функция выдачи прав на запуск скриптов
add_right_running() {
    log_message "Выдаём права на запуск скриптов..."

    # Сохраняем текущую директорию
    CURRENT_DIR=$(pwd)

    # Выдаём права на запуск для After_reboot.sh
    if [ -f "./After_reboot.sh" ]; then
        chmod +x "./After_reboot.sh"
        check_success "выдача прав на After_reboot.sh"
    else
        log_error "Файл After_reboot.sh не найден в текущей директории"
    fi

    # Переходим в директорию cmd
    cd ..
    cd ..
    if [ -d "./cmd" ]; then
        cd ./cmd || {
            log_error "Не удалось перейти в директорию ./cmd"
            return 1
        }
    else
        log_error "Директория ./cmd не найдена"
        return 1
    fi

    # Выдаём права на запуск для скриптов в папке child
    if [ -d "./child" ]; then
        for script in ./child/*.sh; do
            if [ -f "$script" ]; then
                chmod +x "$script"
                check_success "выдача прав на $(basename "$script")"
            fi
        done
    else
        log_error "Директория ./child не найдена"
        cd "$CURRENT_DIR" # Возвращаемся в исходную директорию
        return 1
    fi

    # Возвращаемся в исходную директорию
    cd "$CURRENT_DIR" || {
        log_error "Не удалось вернуться в исходную директорию"
        return 1
    }

    log_success "Выдача прав на запуск скриптов успешно произведена"
}

# Функция создания бэкапов
create_backups() {
    log_message "Создание бэкапов..."

    # Переходим на главного родителя
    cd ..
    cd ..

    # Создаём структуру папок для бэкапов
    mkdir -p ./backups/{systemd,security,default}
    check_success "создание папок для бэкапов"

    # Массив файлов для бэкапа в корневую папку backups
    ROOT_BACKUPS=(
        "/etc/pacman.conf"
        "/etc/mkinitcpio.conf"
        "/etc/environment"
        "/etc/fstab"
    )

    # Массив файлов для бэкапа в папку backups/systemd
    SYSTEMD_BACKUPS=(
        "/etc/systemd/system.conf"
        "/etc/systemd/user.conf"
    )

    # Копируем файлы в корневую папку бэкапов
    for file in "${ROOT_BACKUPS[@]}"; do
        # Получаем только имя файла без пути
        filename=$(basename "$file")
        # Проверяем, существует ли уже файл в папке бэкапов
        if [ -f "./backups/$filename" ]; then
            log_warning "Файл $filename уже существует в папке бэкапов, пропускаем"
        else
            cp "$file" ./backups/
            check_success "скопировали $file"
        fi
    done

    # Копируем файлы в папку systemd
    for file in "${SYSTEMD_BACKUPS[@]}"; do
        # Получаем только имя файла без пути
        filename=$(basename "$file")
        # Проверяем, существует ли уже файл в папке бэкапов
        if [ -f "./backups/systemd/$filename" ]; then
            log_warning "Файл $filename уже существует в папке бэкапов/systemd, пропускаем"
        else
            cp "$file" ./backups/systemd/
            check_success "скопировали $file"
        fi
    done

    # Копируем остальные файлы
    if [ -f "./backups/security/limits.conf" ]; then
        log_warning "Файл limits.conf уже существует в папке бэкапов/security, пропускаем"
    else
        cp /etc/security/limits.conf ./backups/security/
        check_success "скопировали /etc/security/limits.conf"
    fi

    if [ -f "./backups/default/grub" ]; then
        log_warning "Файл grub уже существует в папке бэкапов/default, пропускаем"
    else
        cp /etc/default/grub ./backups/default/
        check_success "скопировали /etc/default/grub"
    fi

    log_success "Создание бэкапов успешно произведено"
}

# Основная функция
main() {
    log_message "Начало установки пред-необходимых действий..."

    add_right_running
    create_backups

    log_success "Установка пред-необходимых действий успешно произведена"
    log_message "Начинается работа по пост-оптимизации системы..."
    log_warning "--> ПРОСЬБА НЕ УХОДИТЬ ПОТОМУ ЧТО НЕОБХОДИМО БУДЕТ ВВОДИТЬ ПАРОЛЬ SUDO В РАЗНЫЕ МОМЕНТЫ ВРЕМЕНИ! <--"

    # Запускаем скрипты последовательно
    sudo ./cmd/child/keyring_p0.sh && \
    sudo ./cmd/child/main_p1.sh && \
    ./cmd/child/yay_p2.sh && \
    sudo ./cmd/child/sys_optimize_p3.sh
}

# Запуск основной функции
main