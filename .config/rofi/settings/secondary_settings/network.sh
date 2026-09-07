#!/usr/bin/env bash

choice=$(echo -e "  Wifi\n󰂯 Bluetooth\n Back" | rofi -dmenu -l 3 -p "Network Settings")

case "$choice" in
    "  Wifi")
	networkmanager_dmenu
	;;
    "󰂯 Bluetooth")
        bzmenu -l rofi
	;;
    " Back")
        $HOME/dotfiles/.config/rofi/settings/settings_menu.sh
        ;;
    *)
        exit 0
        ;;
esac
