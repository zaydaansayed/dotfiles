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
    local capacity=$1
    local charging=$2
    local icon

    if [[ "$charging" == "1" ]]; then
        icon="󰂄"
    else
        icon=$(get_battery_icon "$capacity")
    fi

    echo "${icon} ${capacity}%"
}

last_state=""
triggered_10=false
triggered_5=false

check_battery_thresholds() {
    local capacity=$1
    local charging=$2

    if [[ "$charging" == "1" ]]; then
        triggered_10=false
        triggered_5=false
        return
    fi

    if [[ $capacity -le 5 ]]; then
        if [[ "$triggered_5" == false ]]; then
            ~/dotfiles/.config/eww/scripts/5%bat.sh > /dev/null 2>&1 & 
            
            triggered_5=true
            triggered_10=true 
        fi
    elif [[ $capacity -le 10 ]]; then
        if [[ "$triggered_10" == false ]]; then
            ~/dotfiles/.config/eww/scripts/10%bat.sh > /dev/null 2>&1 &

            triggered_10=true
        fi
    else
        triggered_10=false
        triggered_5=false
    fi
}

output_status() {
    local capacity
    capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
    [[ -z "$capacity" ]] && capacity=0

    local charging
    charging=$(cat /sys/class/power_supply/AC/online 2>/dev/null || cat /sys/class/power_supply/ADP1/online 2>/dev/null)
    [[ -z "$charging" ]] && charging=0

    local current_state
    current_state=$(get_status_string "$capacity" "$charging")

    if [[ "$current_state" != "$last_state" ]]; then
        echo "$current_state"
        last_state="$current_state"
    fi

    check_battery_thresholds "$capacity" "$charging"
}

output_status

while true; do
    read -t 60 -r _
    output_status
done < <(udevadm monitor --subsystem=power_supply --udev)
