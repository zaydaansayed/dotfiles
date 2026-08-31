#!/usr/bin/env bash

choice=$(echo -e " Themes\n󰚩 AI menu\n  Bar\n󱂩 Dock\n󰍜 Main menu\n Player\n󱁖 Popups\n Quick settings\n󰎟 System notification\n󰫧 Variables\n Customisation\n Back" | fuzzel --dmenu --prompt="UI Settings: ")

case "$choice" in
    " Themes")
	eww open theme_picker
	;;
    "󰚩 AI menu")
        kitty -e nvim $HOME/dotfiles/.config/eww/yuck/ai.yuck &
        ;;
    "  Bar")
        kitty -e nvim $HOME/dotfiles/.config/eww/yuck/bar.yuck &
        ;;
    "󱂩 Dock")
       kitty -e nvim $HOME/dotfiles/.config/eww/yuck/dock.yuck &
        ;;
    "󰍜 Main menu")
	kitty -e nvim $HOME/dotfiles/.config/eww/yuck/main_menu.yuck &
	;;
    " Player")
	kitty -e nvim $HOME/dotfiles/.config/eww/yuck/player.yuck &
	;;
    "󱁖 Popups")
        kitty -e nvim $HOME/dotfiles/.config/eww/yuck/popups.yuck &
	;;
    " Quick settings")
	kitty -e nvim $HOME/dotfiles/.config/eww/yuck/quick_settings.yuck &
        ;;
    "󰎟 System notification")
	kitty -e nvim $HOME/dotfiles/.config/eww/yuck/sysnotif.yuck &
	;;
    "󰫧 Variables")
	kitty -e nvim $HOME/dotfiles/.config/eww/yuck/variables.yuck &
	;;
    " Customisation")
	kitty -e nvim $HOME/dotfiles/.config/eww/eww.scss &
	;;
    " Back")
        $HOME/dotfiles/.config/fuzzel/settings/settings_menu.sh &
	;;
    *)
        exit 0
        ;;
esac
