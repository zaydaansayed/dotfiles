#!/bin/bash

LAST_OUTPUT=""

get_internet() {
    local net_state netname icon strength new_output
    
    net_state=$(nmcli networking)
    netname=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2)
    
    if [[ "$net_state" != "enabled" ]]; then
        icon="󰤭"
    elif ip route | grep -q "dev eth" || ip route | grep -q "dev enp"; then
        icon=""
    else
        strength=$(nmcli -t -f SIGNAL,ACTIVE dev wifi 2>/dev/null | awk -F: '$2=="yes" {print $1}')
        
        if [[ -z "$strength" || "$strength" -eq 0 ]]; then icon="󰤯"
        elif [[ $strength -le 25 ]]; then icon="󰤟" 
        elif [[ $strength -le 50 ]]; then icon="󰤢" 
        elif [[ $strength -le 75 ]]; then icon="󰤥" 
        else icon="󰤨"
        fi
    fi

    new_output="{\"icon\": \"$icon\", \"netname\": \"$netname\"}"

    if [[ "$new_output" != "$LAST_OUTPUT" ]]; then
        echo "$new_output"
        LAST_OUTPUT="$new_output"
    fi
}

get_internet

(
    while true; do
        sleep 60
        get_internet
    done
) &

nmcli monitor 2>/dev/null | while read -r _; do
    get_internet
done
