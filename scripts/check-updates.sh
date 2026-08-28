#!/bin/bash
# Prüft auf Pacman- und AUR-Updates
# Synchronisiert zuerst die Datenbanken, dann werden Updates gezählt

# Pacman-Updates (mit fakeroot für checkupdates)
pacman_updates=0
if command -v checkupdates &> /dev/null; then
    # checkupdates synchronisiert die DB und zählt Updates
    pacman_updates=$(checkupdates 2>/dev/null | wc -l)
fi

# AUR-Updates (paru oder yay)
aur_updates=0
if command -v paru &> /dev/null; then
    aur_updates=$(paru -Qua 2>/dev/null | wc -l)
elif command -v yay &> /dev/null; then
    aur_updates=$(yay -Qua 2>/dev/null | wc -l)
fi

# Gesamtanzahl
total_updates=$((pacman_updates + aur_updates))

echo "$total_updates"
