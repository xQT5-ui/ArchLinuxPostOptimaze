
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

# Функция выдачи прав на запуск скриптов
add_right_running() {
    log_message "We grant the rights to run scripts..."

    # Сохраняем текущую директорию
    CURRENT_DIR=$(pwd)

    # Выдаём права на запуск для After_reboot.sh
    if [ -f "./After_reboot.sh" ]; then
        chmod +x "./After_reboot.sh"
        check_success "grant the rights to 'After_reboot.sh'"
    else
        log_error "The 'After_reboot.sh' file was not found in the current directory"
    fi

    # Переходим в директорию cmd
    cd ..
    cd ..
    if [ -d "./cmd" ]; then
        cd ./cmd || {
            log_error "Couldn't navigate to the directory './cmd'"
            return 1
        }
    else
        log_error "The directory './cmd' not found"
        return 1
    fi

    # Выдаём права на запуск для скриптов в папке child
    if [ -d "./child" ]; then
        for script in ./child/*.sh; do
            if [ -f "$script" ]; then
                chmod +x "$script"
                check_success "grant the rights to '$(basename "$script")'"
            fi
        done
    else
        log_error "The directory './child' not found"
        cd "$CURRENT_DIR" # Возвращаемся в исходную директорию
        return 1
    fi

    # Возвращаемся в исходную директорию
    cd "$CURRENT_DIR" || {
        log_error "Couldn't return to the original directory"
        return 1
    }

    log_success "The rights to run scripts have been successfully granted"
}

# Функция создания бэкапов
create_backups() {
    log_message "Creating backups..."

    # Переходим на главного родителя
    cd ..
    cd ..

    # Создаём структуру папок для бэкапов
    mkdir -p ./backups/{systemd,security,default}
    check_success "creating folders for backups"

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
            log_warning "The '$filename' file already exists in the backups folder, skip it"
        else
            cp "$file" ./backups/
            check_success "copied '$file'"
        fi
    done

    # Копируем файлы в папку systemd
    for file in "${SYSTEMD_BACKUPS[@]}"; do
        # Получаем только имя файла без пути
        filename=$(basename "$file")
        # Проверяем, существует ли уже файл в папке бэкапов
        if [ -f "./backups/systemd/$filename" ]; then
            log_warning "The '$filename' already exists in the backups/systemd folder, skip it"
        else
            cp "$file" ./backups/systemd/
            check_success "copied '$file'"
        fi
    done

    # Копируем остальные файлы
    if [ -f "./backups/security/limits.conf" ]; then
        log_warning "The 'limits.conf' file already exists in the backups/security folder, skip it"
    else
        cp /etc/security/limits.conf ./backups/security/
        check_success "copied '/etc/security/limits.conf'"
    fi

    if [ -f "./backups/default/grub" ]; then
        log_warning "The 'grub' file already exists in the backups/default folder, skip it"
    else
        cp /etc/default/grub ./backups/default/
        check_success "copied /etc/default/grub"
    fi

    log_success "Backups were created successfully"
}

# Основная функция
main() {
    log_message "The beginning of the installation of pre-necessary actions..."

    add_right_running
    create_backups

    log_success "Installation of pre-necessary actions has been successfully performed"
    log_message "Work begins on post-optimization of the system..."
    log_warning "--> PLEASE DO NOT LEAVE BECAUSE YOU WILL NEED TO ENTER THE SUDO PASSWORD AT DIFFERENT POINTS IN TIME! <--"

    # Запускаем скрипты последовательно
    sudo ./cmd/child/keyring_p0.sh && \
    sudo ./cmd/child/main_p1.sh && \
    ./cmd/child/yay_p2.sh && \
    sudo ./cmd/child/sys_optimize_p3.sh
}

# Запуск основной функции
main