#!/bin/bash

selected_app=$(eww get selected_app)
instances=$(hyprctl clients | grep -i "class: $selected_app" | grep -v "hyprctl clients" | wc -l | awk '{print $1 / 2}')

if [[ $instances -gt 1 ]]; then 
	eww open --no-daemonize app_multiple_instances
else 
        hyprctl dispatch "hl.dsp.focus({ window = \"class:$selected_app\" })"
fi
