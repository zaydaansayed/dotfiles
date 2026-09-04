
#!/usr/bin/env bash

choice=$(echo -e "  Wifi\n󰂯 Bluetooth\n Back" | fuzzel --dmenu --lines 3 --prompt="Network Settings: ")

case "$choice" in
    "  Wifi")
	networkmanager_dmenu
	;;
    "󰂯 Bluetooth")
        bzmenu -l fuzzel
	;;
    " Back")
        $HOME/dotfiles/.config/fuzzel/settings/settings_menu.sh
        ;;
    *)
        exit 0
        ;;
esac
