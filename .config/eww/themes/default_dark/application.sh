#!/bin/bash

echo "@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/ai.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/bar.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/dock.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/main_menu.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/player.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/popups.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/quick_settings.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/sysnotif.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/widgets/theme_picker.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/base.scss';
@use '$HOME/.config/eww/themes/default_dark/eww/scss/mixins.scss'" > $HOME/.config/eww/eww.scss

echo "(include './yuck/variables.yuck')
(include './themes/default_dark/eww/yuck/bar.yuck')
(include './yuck/popups.yuck')
(include './yuck/quick_settings.yuck')
(include './themes/default_dark/eww/yuck/player.yuck')
(include './yuck/ai.yuck')
(include './themes/default_dark/eww/yuck/dock.yuck')
(include './yuck/sysnotif.yuck')
(include './themes/default_dark/eww/yuck/main_menu.yuck')
(include './yuck/theme_picker.yuck')
(include './yuck/test.yuck')" > $HOME/.config/eww/eww.yuck

echo "[main]
include=$HOME/.config/eww/themes/default_dark/fuzzel.ini
" > $HOME/.config/fuzzel/fuzzel.ini

echo "default_dark" > $HOME/.config/eww/themes/current_theme.txt

sed -i '3c\    path = $HOME/.config/eww/themes/default_dark/images/wallpaper.png' $HOME/.config/hypr/hyprpaper.conf

killall hyprpaper
hyprpaper &

gsettings set org.gnome.desktop.interface icon-theme "adwaita"
