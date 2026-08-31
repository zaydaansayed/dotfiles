#!/bin/bash

echo "@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/ai.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/bar.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/dock.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/main_menu.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/player.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/popups.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/quick_settings.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/sysnotif.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/theme_picker.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/base.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/mixins.scss'" > $HOME/.config/eww/eww.scss

echo "[main]
include=$HOME/.config/eww/themes/night_sky/fuzzel.ini
" > $HOME/.config/fuzzel/fuzzel.ini

echo "night_sky" > $HOME/.config/eww/themes/current_theme.txt

echo "(include './themes/night_sky/eww/yuck/bar.yuck')" > $HOME/.config/eww/yuck/bar.yuck
echo "(include './themes/night_sky/eww/yuck/player.yuck')" > $HOME/.config/eww/yuck/player.yuck

sed -i '3c\    path = $HOME/.config/eww/themes/night_sky/images/wallpaper.png' $HOME/.config/hypr/hyprpaper.conf

killall hyprpaper
hyprpaper &
