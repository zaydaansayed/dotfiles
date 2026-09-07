#!/bin/bash

open_windows=$(eww active-windows | awk -F': ' '{print $2}' | grep -vx -e "bar" -e "dock" | grep -v '^$' | sort -u)

if [[ -z "$open_windows" ]]; then
	hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "", key = "Escape" })'
else
	echo "$open_windows" | while IFS= read -r win; do
		[[ -n "$win" ]] && eww close "$win"
		eww update quick_toggle=false
		eww update music_toggle=false
		eww update main_toggle=false
		eww update tray_toggle=false
		$HOME/.config/eww/scripts/ai_menu_close.sh 
		$HOME/.config/eww/scripts/aipopup_close.sh
		eww update ai_toggle=false 
		killall ollama
		eww update launcher_query=""
		eww update launcher_dinput=""
	done
fi
