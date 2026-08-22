
#!/usr/bin/env bash

choice=$(echo -e "󰌢 System-info(fastfetch)\n Support\n Back" | fuzzel --dmenu --prompt="About and Support: ")

case "$choice" in
    "󰌢 System-info(fastfetch)")
        kitty --class fastfetch-term --hold -e fastfetch &
        ;;
    " Support")
        
        ;;
    " Back")
        $HOME/dotfiles/.config/fuzzel/settings/settings_menu.sh
	;;
    *)
        exit 0
        ;;
esac
