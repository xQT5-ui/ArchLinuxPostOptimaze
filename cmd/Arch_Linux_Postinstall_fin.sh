#!/bin/bash

# 9. Работа с PipeWire
   log_message "Включение PipeWire..."
   systemctl --user enable --now pipewire pipewire.socket pipewire-pulse wireplumber
   check_success "включение PipeWire"

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

   # Маскирование ненужных служб GNOME
   log_message "Маскирование ненужных служб GNOME..."
   systemctl --user mask org.gnome.SettingsDaemon.Wacom.service org.gnome.SettingsDaemon.Smartcard.service
   check_success "маскирование ненужных служб GNOME"

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
