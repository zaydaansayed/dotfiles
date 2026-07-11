#!/bin/bash

get_internet() {
    local net_state
    net_state=$(nmcli -t -f NETWORKING networking 2>/dev/null)
    
    if [[ "$net_state" != "enabled" ]]; then
        echo "󰤭 "
    elif ip route | grep -q "dev eth" || ip route | grep -q "dev enp"; then
        echo " "
    else
        local strength
        strength=$(nmcli -t -f SIGNAL,ACTIVE dev wifi 2>/dev/null | awk -F: '$2=="yes" {print $1}')
        
        if [[ -z "$strength" || "$strength" -eq 0 ]]; then icon="󰤯 "
        elif [[ $strength -le 25 ]]; then icon="󰤟 " 
        elif [[ $strength -le 50 ]]; then icon="󰤢 " 
        elif [[ $strength -le 75 ]]; then icon="󰤥 " 
        else icon="󰤨 "
        fi
        echo "$icon"
    fi
}

get_internet

awk_poll() {
    while true; do
        sleep 5
        get_internet
    done
}
awk_poll &

nmcli monitor 2>/dev/null | while read -r line; do
    if echo "$line" | grep -qE "connected|disconnected|unavailable"; then
        get_internet
    fi
done
