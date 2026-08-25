#!/bin/bash
# Prüft auf Pacman-Updates

# Prüfe ob checkupdates verfügbar ist
if ! command -v checkupdates &> /dev/null; then
    echo "0"
    exit 0
fi

# Hole Pacman-Updates
updates=$(checkupdates 2>/dev/null | wc -l)

echo "$updates"
