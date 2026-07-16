#!/bin/bash

get_bt_status() {
    local bt_show
    bt_show=$(bluetoothctl show 2>/dev/null)

    if [[ "$bt_show" == *"Powered: yes"* ]]; then
        echo "enabled"
    else
        echo "disabled"
    fi
}

get_bt_status

gdbus monitor --system --dest org.bluez 2>/dev/null | while read -r line; do
    if [[ "$line" =~ "Connected" || "$line" =~ "Powered" || "$line" =~ "InterfacesAdded" ]]; then
        get_bt_status
    fi
done
