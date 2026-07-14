#!/bin/bash

check_status() {
    if OUTPUT=$(makoctl history 2>/dev/null); then
        if [ -n "$OUTPUT" ]; then
            echo "true"
        else
            echo "false"
        fi
    else
        echo "false"
    fi
}

check_status

stdbuf -oL dbus-monitor "interface='org.freedesktop.Notifications'" \
                       "interface='org.freedesktop.DBus',member='NameOwnerChanged'" 2>/dev/null | \
grep --line-buffered -E "Notify|NotificationClosed|NameOwnerChanged" | \
while read -r _; do
    sleep 0.05
    check_status
done
