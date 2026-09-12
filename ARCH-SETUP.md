# Arch Linux – Setup nach Neuinstallation

## 1. Pakete installieren

### Basis + X11
sudo pacman -S base-devel xorg-server xorg-xinit xorg-xrandr xorg-xsetroot

### Desktop
sudo pacman -S quickshell picom alacritty thunar nwg-look azote feh

### Laufwerke
sudo pacman -S udisks2 udiskie gvfs gvfs-mtp ntfs-3g exfatprogs ifuse

### Audio (kritisch!)
sudo pacman -S pipewire pipewire-pulse pipewire-alsa pipewire-audio wireplumber rtkit
sudo systemctl enable --now rtkit-daemon

### Polkit
sudo pacman -S polkit polkit-gnome dbus

### GTK/Themes
sudo pacman -S gtk3 gtk4 nordic-theme

### Browser (AUR)
paru -S brave-bin

### PDF
sudo pacman -S masterpdfeditor

## 2. sudoers-Regel fuer passwortlose Updates

echo "georg ALL=(ALL) NOPASSWD: /usr/bin/pacman" | sudo tee /etc/sudoers.d/nopasswd-pacman
sudo chmod 440 /etc/sudoers.d/nopasswd-pacman

## 3. Repo klonen und installieren

git clone git@github.com:gkap28/arch-dwm-quickshell.git ~/Projekte/arch-dwm-quickshell
cd ~/Projekte/arch-dwm-quickshell
sudo make install OWNER=$USER

## 4. GTK-Theme

~/.local/share/dwm-titus/scripts/theme-apply.sh

## 5. PDF/Bilder-Standards

xdg-mime default net.code-industry.masterpdfeditor5.desktop application/pdf
xdg-mime default feh.desktop image/jpeg image/png image/webp image/gif image/bmp image/tiff

## 6. SSH-Key fuer GitHub

ssh-keygen -t ed25519 -C "georg.kalaitzis@hotmail.com"
cat ~/.ssh/id_ed25519.pub
# Public Key bei https://github.com/settings/keys eintragen
