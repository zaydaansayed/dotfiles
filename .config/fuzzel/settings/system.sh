#!/usr/bin/env bash

choice=$(echo -e "Monitors\nUI\nAbout and support" | fuzzel --dmenu --prompt="Settings: ")

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
    *)
        exit 0
        ;;
esac


