#!/bin/bash

echo "@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/bar.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/dock.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/main_menu.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/player.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/popups.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/quick_settings.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/sysnotif.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/settings.scss';
@use '$HOME/.config/eww/scss/launcher.scss';
@use '$HOME/.config/eww/scss/clipboard.scss';
@use '$HOME/.config/eww/scss/clock.scss';
@use '$HOME/.config/eww/scss/widgets.scss';
@use '$HOME/.config/eww/scss/keybinds.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/base.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/mixins.scss'" > $HOME/.config/eww/eww.scss

echo "(include './yuck/variables.yuck')
(include './themes/default_dark/eww/yuck/bar.yuck')
(include './themes/default_dark/eww/yuck/popups.yuck')
(include './themes/default_dark/eww/yuck/quick_settings.yuck')
(include './themes/default_dark/eww/yuck/player.yuck')
(include './themes/default_dark/eww/yuck/dock.yuck')
(include './yuck/sysnotif.yuck')
(include './themes/default_dark/eww/yuck/main_menu.yuck')
(include './yuck/launcher.yuck')
(include './yuck/clipboard.yuck')
(include './yuck/clock.yuck')
(include './yuck/widgets.yuck')
(include './yuck/keybinds.yuck')
(include './yuck/setup.yuck')
(include './yuck/emoji.yuck')
(include './themes/default_dark/eww/yuck/settings.yuck')" > $HOME/.config/eww/eww.yuck

sed -i '14s/.*/            active_border   = "rgb(ffffff)",/' $HOME/.config/hypr/modules/look_feel.lua

# Absolute wallpaper path (hyprpaper does not expand $HOME) + detached restart
# so the new hyprpaper survives the terminal that runs this script.
sed -i "3c\    path = $HOME/.config/eww/themes/default_dark/images/wallpaper.png" $HOME/.config/hypr/hyprpaper.conf
echo "source = $HOME/.config/eww/themes/default_dark/hypr/hyprlock.conf" > $HOME/.config/hypr/hyprlock.conf

killall hyprpaper 2>/dev/null || true
sleep 0.5
setsid nohup hyprpaper >/dev/null 2>&1 < /dev/null &
disown 2>/dev/null || true

gsettings set org.gnome.desktop.interface icon-theme "Adwaita"
gsettings set org.gnome.desktop.interface font-name "Adwaita Sans 11"
gsettings set org.gnome.desktop.interface document-font-name "Adwaita Sans 12"
gsettings set org.gnome.desktop.interface monospace-font-name "JetBrainsMono Nerd Font 11"

DD="$HOME/.config/eww/themes/default_dark"
unlink $HOME/.config/kitty/kitty.conf 2>/dev/null
link $DD/kitty.conf $HOME/.config/kitty/kitty.conf
unlink $HOME/.config/nvim/lua/config/theme.lua 2>/dev/null
unlink $HOME/.config/yazi/theme.toml 2>/dev/null
unlink $HOME/.config/cava/themes/night_sky 2>/dev/null
unlink $HOME/.config/fastfetch/config.jsonc 2>/dev/null
unlink $HOME/.config/fish/functions/fish_prompt.fish 2>/dev/null
unlink $HOME/.config/fish/functions/fish_right_prompt.fish 2>/dev/null
unlink $HOME/.config/fish/config.fish 2>/dev/null
link $DD/fish/config.fish $HOME/.config/fish/config.fish
unlink $HOME/.config/opencode/themes/night-sky.json 2>/dev/null

sed -i "s|^theme = 'night_sky'$|; theme = 'none'|" "$HOME/.config/cava/config"

rm $HOME/.config/opencode/tui.json

echo "default_dark" > $HOME/.config/eww/themes/current_theme.txt
eww update connections_vis=false ui_vis=true
