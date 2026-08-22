
#!/usr/bin/env bash

choice=$(echo -e "System-info(fastfetch)\nSupport\n Back" | fuzzel --dmenu --prompt="About and Support: ")

case "$choice" in
    "System-info(fastfetch)")
        firefox &
        ;;
    "Support")
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
