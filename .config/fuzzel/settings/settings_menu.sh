#!/usr/bin/env bash

choice=$(echo -e "󰛳 Network\n Audio\n System\n UI\n About and support" | fuzzel --lines 5 --dmenu --prompt="Settings: ")

case "$choice" in
    "󰛳 Network")
	$HOME/dotfiles/.config/fuzzel/settings/secondary_settings/network.sh
	;;
    " Audio")
        pwmenu --launcher fuzzel
	;;
    " System")
        $HOME/dotfiles/.config/fuzzel/settings/secondary_settings/system.sh
        ;;
    " UI")
        $HOME/dotfiles/.config/fuzzel/settings/secondary_settings/ui.sh
        ;;
    " About and support")
        $HOME/dotfiles/.config/fuzzel/settings/secondary_settings/about_support.sh
        ;;
    *)
        exit 0
        ;;
esac
