cd $HOME/dotfiles
stow .
touch $HOME/.cargo/env.fish
mkdir $HOME/.local/share/applications/
mv $HOME/dotfiles/applications/keybinds.desktop $HOME/.local/share/applications/keybinds.desktop
mv $HOME/dotfiles/applications/settings.desktop $HOME/.local/share/applications/settings.desktop
sudo rm /usr/share/icons/hicolor/128x128/apps/nvim.png
sudo rm /usr/share/icons/pixora/16/apps/nvim.png
sudo mv $HOME/dotfiles/icons/nvim-hicolor.svg /usr/share/icons/hicolor/scalable/apps/nvim.svg
sudo mv $HOME/dotfiles/icons/nvim-pixora.svg /usr/share/icons/pixora/scalable/apps/nvim.svg
sudo gtk-update-icon-cache -f /usr/share/icons/hicolor /usr/share/icons/pixora
mkdir $HOME/.config/opencode/themes
$HOME/.config/eww/themes/night_sky/application.sh

echo 'hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
hl.exec_cmd("wl-paste --watch cliphist store")
hl.exec_cmd("hypridle")
hl.exec_cmd("mako")
hl.exec_cmd("~/dotfiles/.config/eww/scripts/notification_popup.sh")
hl.exec_cmd("eww daemon")
hl.exec_cmd("eww open --no-daemonize setup")
hl.exec_cmd("hyprpaper")
hl.exec_cmd("udiskie --tray")' > $HOME/.config/hypr/modules/autostart.lua

echo "zen
yazi
nvim" > $HOME/.config/eww/scripts/pinned_apps.conf

echo "#############################################
##PLEASE RESTART HYPRLAND TO FINISH SETUP!!##
#############################################"
