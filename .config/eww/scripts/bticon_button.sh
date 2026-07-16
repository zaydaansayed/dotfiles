#!/bin/bash

get_bt() {
    local bt_show
    bt_show=$(bluetoothctl show 2>/dev/null)

    if [[ "$bt_show" == *"Powered: yes"* ]]; then
        if [[ -n "$(bluetoothctl devices Connected 2>/dev/null)" ]]; then
            echo "󰂱 "
        else
            echo "󰂯"
        fi
    else
        echo "󰂲"
    fi
}

get_bt

gdbus monitor --system --dest org.bluez 2>/dev/null | while read -r line; do
    if [[ "$line" =~ "Connected" || "$line" =~ "Powered" || "$line" =~ "InterfacesAdded" ]]; then
        get_bt
    fi
done
