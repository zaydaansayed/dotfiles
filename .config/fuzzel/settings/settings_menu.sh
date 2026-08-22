#!/usr/bin/env bash

choice=$(echo -e "System\nUI\nAbout and support" | fuzzel --dmenu --prompt="Settings: ")

case "$choice" in
    "System")
        firefox &
        ;;
    "UI")
        foot &
        ;;
    "About and support")
        pavucontrol &
        ;;
    *)
        exit 0
        ;;
esac

