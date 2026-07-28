#!/bin/bash

get_battery_icon() {
    local cap=$1
    if [[ $cap -le 10 ]]; then echo "󰁺"
    elif [[ $cap -le 20 ]]; then echo "󰁻"
    elif [[ $cap -le 30 ]]; then echo "󰁼"
    elif [[ $cap -le 40 ]]; then echo "󰁽"
    elif [[ $cap -le 50 ]]; then echo "󰁾"
    elif [[ $cap -le 60 ]]; then echo "󰁿"
    elif [[ $cap -le 70 ]]; then echo "󰂀"
    elif [[ $cap -le 80 ]]; then echo "󰂁"
    elif [[ $cap -le 90 ]]; then echo "󰂂"
    else echo "󰁹"
    fi
}

get_status_string() {
    local capacity
    capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
    [[ -z "$capacity" ]] && capacity=0

    local charging
    charging=$(cat /sys/class/power_supply/AC/online 2>/dev/null || cat /sys/class/power_supply/ADP1/online 2>/dev/null)

    local icon
    if [[ "$charging" == "1" ]]; then
        icon="󰂄"
    else
        icon=$(get_battery_icon "$capacity")
    fi

    echo "${icon} ${capacity}%"
}

last_state=""

output_status() {
    local current_state
    current_state=$(get_status_string)

    if [[ "$current_state" != "$last_state" ]]; then
        echo "$current_state"
        last_state="$current_state"
    fi
}

output_status

udevadm monitor --subsystem=power_supply --udev | while true; do

    read -t 60 -r _
    
    output_status
done
