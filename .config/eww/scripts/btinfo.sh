#!/bin/bash

get_bt() {
    local bt_show
    bt_show=$(bluetoothctl show 2>/dev/null)
    devcname=$(bluetoothctl devices Connected | cut -d ' ' -f 3-)

    if [[ "$bt_show" == *"Powered: yes"* ]]; then
        if [[ -n "$(bluetoothctl devices Connected 2>/dev/null)" ]]; then
            icon="󰂱"
    else
            icon="" 
        fi
    else
        icon="󰂲"
    fi
    echo "{\"icon\": \"$icon\", \"devcname\": \"$devcname\"}"
}

get_bt

while true; do
    gdbus monitor --system --dest org.bluez 2>/dev/null | while read -r line; do
        if [[ "$line" =~ "Connected" || "$line" =~ "Powered" || "$line" =~ "InterfacesAdded" ]]; then
            get_bt
        fi
    done
    
    sleep 2
    
    get_bt 
done

