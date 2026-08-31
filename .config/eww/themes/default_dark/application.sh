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

echo "[main]
include=$HOME/.config/eww/themes/default_dark/fuzzel.ini
" > $HOME/.config/fuzzel/fuzzel.ini

echo "default_dark" > $HOME/.config/eww/themes/current_theme.txt

echo "(include './themes/default_dark/eww/yuck/bar.yuck')" > $HOME/.config/eww/yuck/bar.yuck
echo "(include './themes/default_dark/eww/yuck/player.yuck')" > $HOME/.config/eww/yuck/player.yuck

sed -i '3c\    path = $HOME/.config/eww/themes/default_dark/images/wallpaper.png' $HOME/.config/hypr/hyprpaper.conf

killall hyprpaper
hyprpaper &
