#!/bin/bash

dbus-monitor "interface='org.freedesktop.Notifications',member='Notify'" | while read -r line; do
    if echo "$line" | grep -q "method call"; then
        
        read -r app_line
        read -r id_line
        read -r icon_line
        read -r summary_line
        read -r body_line
        
        APP_NAME=$(echo "$app_line" | cut -d '"' -f 2)
        NOTIF_TITLE=$(echo "$summary_line" | cut -d '"' -f 2)
        NOTIF_BODY=$(echo "$body_line" | cut -d '"' -f 2)

        (
            eww update notif_app="$APP_NAME"
            eww update notif_title="$NOTIF_TITLE"
            eww update notif_body="$NOTIF_BODY"
            
            eww open notification_popup
            
            sleep 5

            makoctl dismiss
	    eww close notification_popup
        ) &
    fi
done
