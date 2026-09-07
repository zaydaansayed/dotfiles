#!/usr/bin/env bash

choice=$(echo -e "󰛳 Network\n Audio\n System\n UI\n About and support" | rofi -l 5 -dmenu -p "Settings")

case "$choice" in
    "󰛳 Network")
	$HOME/dotfiles/.config/rofi/settings/secondary_settings/network.sh
	;;
    " Audio")
        pwmenu --launcher rofi
	;;
    " System")
        $HOME/dotfiles/.config/rofi/settings/secondary_settings/system.sh
        ;;
    " UI")
        $HOME/dotfiles/.config/rofi/settings/secondary_settings/ui.sh
        ;;
    " About and support")
        $HOME/dotfiles/.config/rofi/settings/secondary_settings/about_support.sh
        ;;
    *)
        exit 0
        ;;
esac
