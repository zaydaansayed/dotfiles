#!/bin/bash

echo "@use /home/.config/eww/themes/default_dark/eww/scss/widgets/ai.scss" > /home/zaydaansayed/dotfiles/.config/eww/scss/widgets/ai.scss
echo "@use /home/.config/eww/themes/default_dark/eww/scss/widgets/bar.scss" > /home/zaydaansayed/dotfiles/.config/eww/scss/widgets/bar.scss
echo "@use /home/.config/eww/themes/default_dark/eww/scss/widgets/dock.scss" > /home/zaydaansayed/dotfiles/.config/eww/scss/widgets/dock.scss
echo "@use /home/.config/eww/themes/default_dark/eww/scss/widgets/main_menu.scss" > /home/zaydaansayed/dotfiles/.config/eww/scss/widgets/main_menu.scss
echo "@use /home/.config/eww/themes/default_dark/eww/scss/widgets/player.scss" > /home/zaydaansayed/dotfiles/.config/eww/scss/widgets/player.scss
echo "@use /home/.config/eww/themes/default_dark/eww/scss/widgets/popups.scss" > /home/zaydaansayed/dotfiles/.config/eww/scss/widgets/popups.scss
echo "@use /home/.config/eww/themes/default_dark/eww/scss/widgets/quick_settings.scss" > /home/zaydaansayed/dotfiles/.config/eww/scss/widgets/quick_settings.scss
echo "@use /home/.config/eww/themes/default_dark/eww/scss/widgets/sysnotif.scss" > /home/zaydaansayed/dotfiles/.config/eww/scss/widgets/sysnotif.scss
echo "@use /home/.config/eww/themes/default_dark/eww/scss/base.scss" > /home/zaydaansayed/dotfiles/.config/eww/scss/base.scss
echo "@use /home/.config/eww/themes/default_dark/eww/scss/colors.scss" > /home/zaydaansayed/dotfiles/.config/eww/scss/colors.scss
echo "@use /home/.config/eww/themes/default_dark/eww/scss/mixins.scss" > /home/zaydaansayed/dotfiles/.config/eww/scss/mixins.scss

sed -i '3c\    path = /home/zaydaansayed/Documents/themes/default_dark/images/wallpaper.png' /home/zaydaansayed/dotfiles/.config/hypr/hyprpaper.conf

killall hyprpaper 
hyprpaper &
