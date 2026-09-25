sudo pacman -S gtk-layer-shell udiskie socat stow jq ttf-jetbrains-mono hyprshot tlp libdbusmenu-gtk3 libdbusmenu-glib base-devel rust yazi neovim firefox fish
cd $HOME
git clone https://aur.archlinux.org/yay.git
cd $HOME/yay
makepkg -si
yay -S weather-cli bibata-cursor-theme otf-monocraft pixora-icons-git
cd $HOME
git clone https://github.com/elkowar/eww
cd $HOME/eww
cargo build --release --no-default-features --features=wayland
sudo mv target/release/eww /usr/bin/
sudo rm -rf $HOME/.config/hypr
cd $HOME/dotfiles
stow .
link $HOME/dotfiles/applications/keybinds.desktop $HOME/.local/share/applications/keybinds.desktop
link $HOME/dotfiles/applications/settings.desktop $HOME/.local/share/applications/settings.desktop
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

echo "#############################################
##PLEASE RESTART HYPRLAND TO FINISH SETUP!!##
#############################################"
