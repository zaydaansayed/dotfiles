#!/bin/bash

echo "@use '$HOME/.config/eww/themes/night_sky/eww/scss/widgets/bar.scss';
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
(include './themes/night_sky/eww/yuck/quick_settings.yuck')
(include './themes/night_sky/eww/yuck/player.yuck')
(include './themes/night_sky/eww/yuck/dock.yuck')
(include './yuck/sysnotif.yuck')
(include './themes/night_sky/eww/yuck/main_menu.yuck')
(include './yuck/launcher.yuck')
(include './yuck/clipboard.yuck')
(include './themes/night_sky/eww/yuck/settings.yuck')" > $HOME/.config/eww/eww.yuck

sed -i '14s/.*/            active_border   = { colors = {"rgb(E99AFF)", "rgb(549D9D)"}, angle = 0 },/' $HOME/.config/hypr/modules/look_feel.lua

sed -i '3c\    path = $HOME/.config/eww/themes/night_sky/images/wallpaper.png' $HOME/.config/hypr/hyprpaper.conf
echo "source = $HOME/.config/eww/themes/night_sky/hypr/hyprlock.conf" > $HOME/.config/hypr/hyprlock.conf

killall hyprpaper 2>/dev/null
hyprpaper &

gsettings set org.gnome.desktop.interface icon-theme "pixora"
gsettings set org.gnome.desktop.interface font-name "Monocraft 11"
gsettings set org.gnome.desktop.interface document-font-name "Monocraft 11"
gsettings set org.gnome.desktop.interface monospace-font-name "Monocraft 11"

NS="$HOME/.config/eww/themes/night_sky"
unlink $HOME/.config/kitty/kitty.conf 2>/dev/null
link $NS/kitty.conf $HOME/.config/kitty/kitty.conf
unlink $HOME/.config/nvim/lua/config/theme.lua 2>/dev/null
link $NS/nvim_theme.lua $HOME/.config/nvim/lua/config/theme.lua
unlink $HOME/.config/yazi/theme.toml 2>/dev/null
link $NS/yazi_theme.toml $HOME/.config/yazi/theme.toml
unlink $HOME/.config/cava/themes/night_sky 2>/dev/null
link $NS/cava_theme $HOME/.config/cava/themes/night_sky
unlink $HOME/.config/fastfetch/config.jsonc 2>/dev/null
link $NS/fastfetch/config.jsonc $HOME/.config/fastfetch/config.jsonc
unlink $HOME/.config/fish/functions/fish_prompt.fish 2>/dev/null
link $NS/fish/prompt.fish $HOME/.config/fish/functions/fish_prompt.fish
unlink $HOME/.config/fish/functions/fish_right_prompt.fish 2>/dev/null
link $NS/fish/right_prompt.fish $HOME/.config/fish/functions/fish_right_prompt.fish
unlink $HOME/.config/fish/config.fish 2>/dev/null
link $NS/fish/config.fish $HOME/.config/fish/config.fish
unlink $HOME/.config/opencode/themes/night-sky.json 2>/dev/null
link $NS/opencode_conf.json $HOME/.config/opencode/themes/night-sky.json

sed -i "s|^; theme = 'none'$|theme = 'night_sky'|" "$HOME/.config/cava/config"
echo '{"$schema": "https://opencode.ai/tui.json", "theme": "night-sky"}' > "$HOME/.config/opencode/tui.json"

echo "night_sky" > $HOME/.config/eww/themes/current_theme.txt
eww update connections_vis=false ui_vis=true
