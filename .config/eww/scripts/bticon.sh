#!/bin/bash

get_bt() {

        if [[ -n "$(bluetoothctl devices Connected 2>/dev/null)" ]]; then
            echo "󰂱"
	else
            echo ""
        fi
}

get_bt

gdbus monitor --system --dest org.bluez 2>/dev/null | while read -r line; do
    if [[ "$line" =~ "Connected" || "$line" =~ "Powered" || "$line" =~ "InterfacesAdded" ]]; then
        get_bt
    fi
done
