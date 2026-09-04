#!/bin/bash

bt_show=$(bluetoothctl show 2>/dev/null)

if [[ "$bt_show" == *"Powered: yes"* ]]; then
    if [[ -n "$(bluetoothctl devices Connected 2>/dev/null)" ]]; then
        bt_icon="󰂱"
    fi
else
    bt_icon=""
fi

net_state=$(nmcli networking)
wifi_state=$(nmcli radio wifi)

if [[ "$net_state" != "enabled" || "$wifi_state" != "enabled" ]]; then
    net_icon="󰤭"
elif ip route | grep -qE "dev (eth|enp)"; then
    net_icon=""
else
    strength=$(nmcli -t -f SIGNAL,ACTIVE dev wifi 2>/dev/null | awk -F: '$2=="yes" {print $1}')
        
    if [[ -z "$strength" || "$strength" -eq 0 ]]; then 
        icon="󰤯"
    elif [[ $strength -le 25 ]]; then net_icon="󰤟" 
    elif [[ $strength -le 50 ]]; then net_icon="󰤢" 
    elif [[ $strength -le 75 ]]; then net_icon="󰤥" 
    else icon="󰤨"
    fi
fi

bat_capacity=$(cat /sys/class/power_supply/BAT0/capacity)
bat_status=$(cat /sys/class/power_supply/AC/online)

if [[ $bat_capacity -le 10 ]]; then bat_icon="󰁺"
elif [[ $bat_capacity -le 20 ]]; then bat_icon="󰁻"
elif [[ $bat_capacity -le 30 ]]; then bat_icon="󰁼"
elif [[ $bat_capacity -le 40 ]]; then bat_icon="󰁽"
elif [[ $bat_capacity -le 50 ]]; then bat_icon="󰁾"
elif [[ $bat_capacity -le 60 ]]; then bat_icon="󰁿"
elif [[ $bat_capacity -le 70 ]]; then bat_icon="󰂀"
elif [[ $bat_capacity -le 80 ]]; then bat_icon="󰂁"
elif [[ $bat_capacity -le 90 ]]; then bat_icon="󰂂"
else bat_icon="󰁹"
fi

if [[ $bat_status == "1" ]]; then bat_icon="󰂄"
fi

echo $bt_icon $net_icon $bat_icon $bat_capacity%
