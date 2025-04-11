#!/bin/bash

# Проверка наличия прав суперпользователя
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт должен быть запущен с правами суперпользователя" 
   exit 1
fi

# 0. Обновление ключей Arch Linux [кажется лучше делать вручную!!!]
echo "Обновление ключей Arch Linux..."

# Обновление зеркал
pacman -S --noconfirm reflector rsync
reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

pacman-key --init
pacman-key --populate archlinux
# следующая операция идёт долго, поэтому весь блок лучше вынести в отдельный формат как вариант!!!
pacman-key --refresh-keys
pacman -Sy
systemctl enable --now archlinux-keyring-wkd-sync.timer
systemctl start archlinux-keyring-wkd-sync.service

echo "Обновление ключей Arch Linux... --> DONE"
