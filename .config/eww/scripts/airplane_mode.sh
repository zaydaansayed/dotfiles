#!/bin/bash

get_airplane() {
    
    airplane_state=$([ -n "$(rfkill list | grep -i "Soft blocked: yes")" ] && echo "enabled" || echo "disabled")
    
    if [[ $airplane_state == "enabled" ]]; then
        echo 󰀝
    else
	echo 󰀞
    fi
}

get_airplane

nmcli monitor 2>/dev/null | while read -r _; do
    get_airplane
done
