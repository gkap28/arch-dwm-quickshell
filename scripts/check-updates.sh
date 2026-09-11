#!/bin/bash
# Prüft verfügbare Updates – erkennt Void Linux und Arch Linux automatisch
# Gibt die Gesamtanzahl der Updates aus (Zahl), eine pro Zeile

# ── Arch Linux ────────────────────────────────────────────────────────────────
if [ -f /etc/arch-release ]; then
    pacman_updates=0
    if command -v checkupdates &> /dev/null; then
        pacman_updates=$(checkupdates 2>/dev/null | wc -l)
    fi

    aur_updates=0
    if command -v paru &> /dev/null; then
        aur_updates=$(paru -Qua 2>/dev/null | wc -l)
    elif command -v yay &> /dev/null; then
        aur_updates=$(yay -Qua 2>/dev/null | wc -l)
    fi

    echo $((pacman_updates + aur_updates))
    exit 0
fi

# ── Void Linux ────────────────────────────────────────────────────────────────
if [ -f /etc/void-release ]; then
    xbps-install -nuM 2>/dev/null | grep -c "^"
    exit 0
fi

# ── Unbekanntes System ────────────────────────────────────────────────────────
echo "0"
