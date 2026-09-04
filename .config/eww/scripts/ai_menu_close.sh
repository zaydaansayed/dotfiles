#!/bin/bash

open_window=$(eww get ai_menu_toggle)

if [[ $open_window == "false" ]]; then
	:
else 
	eww close ai_menu
	eww update ai_menu_toggle=false
fi
