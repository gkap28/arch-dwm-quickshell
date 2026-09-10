#!/bin/sh
# .xinitrc — startx entry point for dwm-titus
#
# Wird von `startx` gelesen. `dbus-run-session` läuft bereits
# durch ~/.zprofile, daher hier KEIN zweites dbus-run-session.
# Alle weiteren Dienste (Quickshell, picom, dunst, dwm-status, …)
# startet dwm selbst über runautostart() → scripts/autostart.sh.

# Monitor-Konfiguration
xrandr --output HDMI-A-0 --mode 2560x1080 --pos 0x0 --rotate normal \
       --output DisplayPort-2 --mode 1920x1080 --pos 2560x0 --rotate normal
xrandr --output HDMI-A-0 --primary

# DWM starten (ruft intern autostart.sh auf)
exec dwm
