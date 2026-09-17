#!/bin/bash

echo "@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/ai.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/bar.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/dock.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/main_menu.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/player.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/popups.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/quick_settings.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/sysnotif.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/settings.scss';
@use '$HOME/.config/eww/scss/launcher.scss';
@use '$HOME/.config/eww/scss/clipboard.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/base.scss';
@use '$HOME/.config/eww/themes/night_sky/eww/scss/mixins.scss'" > $HOME/.config/eww/eww.scss

echo "(include './yuck/variables.yuck')
(include './themes/night_sky/eww/yuck/bar.yuck')
(include './themes/night_sky/eww/yuck/popups.yuck')
(include './yuck/quick_settings.yuck')
(include './themes/night_sky/eww/yuck/player.yuck')
(include './yuck/ai.yuck')
(include './themes/night_sky/eww/yuck/dock.yuck')
(include './yuck/sysnotif.yuck')
(include './themes/night_sky/eww/yuck/main_menu.yuck')
(include './yuck/launcher.yuck')
(include './yuck/clipboard.yuck')
(include './themes/night_sky/eww/yuck/settings.yuck')" > $HOME/.config/eww/eww.yuck

echo "night_sky" > $HOME/.config/eww/themes/current_theme.txt

sed -i '3c\    path = $HOME/.config/eww/themes/night_sky/images/wallpaper.png' $HOME/.config/hypr/hyprpaper.conf
echo "source = $HOME/.config/eww/themes/night_sky/hypr/hyprlock.conf" > $HOME/.config/hypr/hyprlock.conf

killall hyprpaper
hyprpaper &

gsettings set org.gnome.desktop.interface icon-theme "pixora"
