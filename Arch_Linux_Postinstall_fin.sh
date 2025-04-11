#!/bin/bash

# 22. Очистка лишних пакетов и кеша
echo "Очистка лишних пакетов и кеша..."

pacman -Scc --noconfirm && pacman -Rscn $(pacman -Qtdq) --noconfirm

echo "Очистка лишних пакетов и кеша... --> DONE"

# 23. Обновляем initramfs и grub-загрузчик
echo "Обновляем initramfs и grub-загрузчик..."

mkinitcpio -P && grub-mkconfig -o /boot/grub/grub.cfg

echo "Обновляем initramfs и grub-загрузчик... --> DONE"

echo "===== Конец 4-ой части ====="
echo "Установка и оптимизация завершены. Рекомендуется перезагрузить систему."
