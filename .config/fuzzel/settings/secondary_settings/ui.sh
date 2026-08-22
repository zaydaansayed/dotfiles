#!/usr/bin/env bash

choice=$(echo -e "Monitors\nUI\nAbout and support\n Back" | fuzzel --dmenu --prompt="UI Settings: ")

case "$choice" in
    "Monitors")
        firefox &
        ;;
    "UI")
        foot &
        ;;
    "About and support")
        pavucontrol &
        ;;
    " Back")
        $HOME/dotfiles/.config/fuzzel/settings/settings_menu.sh
	;;
    *)
        exit 0
        ;;
esac
