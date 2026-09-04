
#!/usr/bin/env bash

choice=$(echo -e "󰌢 System-info(fastfetch)\n Support\n Back" | fuzzel --lines 3 --dmenu --prompt="About and Support: ")

case "$choice" in
    "󰌢 System-info(fastfetch)")
        kitty --class fastfetch-term --hold -e fastfetch &
        ;;
    " Support")
	firefox https://github.com/zaydaansayed/dotfiles/blob/main/SUPPORT.md
        ;;
    " Back")
        $HOME/dotfiles/.config/fuzzel/settings/settings_menu.sh
	;;
    *)
        exit 0
        ;;
esac
