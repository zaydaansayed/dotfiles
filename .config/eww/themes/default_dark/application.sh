#!/bin/bash

echo "@use '/home/.config/eww/themes/default_dark/eww/scss/widgets/ai.scss';
@use '/home/.config/eww/themes/default_dark/eww/scss/widgets/bar.scss';
@use '/home/.config/eww/themes/default_dark/eww/scss/widgets/dock.scss';
@use '/home/.config/eww/themes/default_dark/eww/scss/widgets/main_menu.scss';
@use '/home/.config/eww/themes/default_dark/eww/scss/widgets/player.scss';
@use '/home/.config/eww/themes/default_dark/eww/scss/widgets/popups.scss';
@use '/home/.config/eww/themes/default_dark/eww/scss/widgets/quick_settings.scss';
@use '/home/.config/eww/themes/default_dark/eww/scss/widgets/sysnotif.scss';
@use '/home/.config/eww/themes/default_dark/eww/scss/widgets/theme_picker.scss';
@use '/home/.config/eww/themes/default_dark/eww/scss/base.scss';
@use '/home/.config/eww/themes/default_dark/eww/scss/mixins.scss'" > /home/.config/eww/eww.scss

echo "[main]
include=/home/zaydaansayed/dotfiles/.config/eww/themes/default_dark/fuzzel.ini
" > /home/.config/fuzzel/fuzzel.ini

echo "default_dark" > /home/.config/eww/themes/current_theme.txt

sed -i '3c\    path = /home/.config/eww/themes/default_dark/images/wallpaper.png' /home/.config/hypr/hyprpaper.conf

killall hyprpaper
hyprpaper &
