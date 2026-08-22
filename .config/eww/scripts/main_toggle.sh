#!/bin/bash

state=$(eww get main_toggle)

if [ "$state" == "true" ]; then
	eww update main_toggle=false
	eww close main_menu
else 
	eww update main_toggle=true
	eww open main_menu
fi
