#!/bin/bash
get_internet() {
    local net_state wifi_state netname icon strength ethernet
    local wifi_on=false net_on=false

    net_state=$(nmcli networking)
    wifi_state=$(nmcli radio wifi)
    [[ "$net_state" == "enabled" ]] && net_on=true
    [[ "$wifi_state" == "enabled" ]] && wifi_on=true

    netname=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2-)

    ethernet=false
    if ip route 2>/dev/null | grep -qE "dev (eth|enp)"; then
        ethernet=true
    fi

    if [[ "$net_state" != "enabled" || "$wifi_state" != "enabled" ]]; then
        icon="󰤭"
    elif [[ "$ethernet" == true ]]; then
        icon=""
    else
        strength=$(nmcli -t -f SIGNAL,ACTIVE dev wifi 2>/dev/null | awk -F: '$2=="yes" {print $1}')

        if [[ -z "$strength" || "$strength" -eq 0 ]]; then
            icon="󰤯"
        elif [[ $strength -le 25 ]]; then icon="󰤟"
        elif [[ $strength -le 50 ]]; then icon="󰤢"
        elif [[ $strength -le 75 ]]; then icon="󰤥"
        else icon="󰤨"
        fi
    fi

    echo { "netname": "$netname", "icon": "$icon" }
}

get_internet

(
    while true; do
        sleep 30
        get_internet
    done
) &

nmcli monitor 2>/dev/null | while read -r _; do
    sleep 0.2
    get_internet
done
