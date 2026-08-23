#!/usr/bin/env bash

choice=$(echo -e "󰍹 Monitors\n󰈆 Auto-Start\n󰫧 Enviroment Variables\n Input and Keybinds\n󰖚 Look and feel\n Miscellaneous\n My Programs\n Windows\n Back" | fuzzel --dmenu --prompt="System Settings: ")

case "$choice" in
    "󰍹 Monitors")
        kitty -e nvim $HOME/dotfiles/.config/hypr/modules/monitors.lua &
        ;;
    "󰈆 Auto-Start")
        kitty -e nvim $HOME/dotfiles/.config/hypr/modules/autostart.lua &
        ;;
    "󰫧 Enviroment Variables")
       kitty -e nvim $HOME/dotfiles/.config/hypr/modules/env_variables.lua &
        ;;
    " Input and Keybinds")
	kitty -e nvim $HOME/dotfiles/.config/hypr/modules/input_keybinds.lua &
	;;
    "󰖚 Look and feel")
	kitty -e nvim $HOME/dotfiles/.config/hypr/modules/look_feel.lua &
	;;
    " Miscellaneous")
        kitty -e nvim $HOME/dotfiles/.config/hypr/modules/misc.lua &
	;;
    " My Programs")
	kitty -e nvim $HOME/dotfiles/.config/hypr/modules/my_programs.lua &
        ;;
    " Windows")
	kitty -e nvim $HOME/dotfiles/.config/hypr/modules/windows.lua &
	;;
    " Back")
        $HOME/dotfiles/.config/fuzzel/settings/settings_menu.sh &
	;;
    *)
        exit 0
        ;;
esac
