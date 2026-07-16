#!/bin/bash
nmcli networking

nmcli monitor | while read -r line; do
    if echo "$line" | grep -q "Connectivity is now\|Networking is now"; then
        nmcli networking
    fi
done

