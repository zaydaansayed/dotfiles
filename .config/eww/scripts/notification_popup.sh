#!/bin/bash

# Listen specifically for the Notify method call
dbus-monitor "interface='org.freedesktop.Notifications',member='Notify'" | while read -r line; do
    if echo "$line" | grep -q "method call"; then
        
        # 1. Read the next few lines from the stream to extract the data safely
        # (D-Bus outputs: App Name, Replaces ID, Icon, Summary, Body...)
        read -r app_line
        read -r id_line
        read -r icon_line
        read -r summary_line
        read -r body_line
        
        # Clean up the strings (removing quotes and structural D-Bus text)
        APP_NAME=$(echo "$app_line" | cut -d '"' -f 2)
        NOTIF_TITLE=$(echo "$summary_line" | cut -d '"' -f 2)
        NOTIF_BODY=$(echo "$body_line" | cut -d '"' -f 2)

        # 2. Background the display logic so the listener stays lightning-fast
        (
            # CRITICAL STEP: Update Eww variables BEFORE opening the window
            eww update notif_app="$APP_NAME"
            eww update notif_title="$NOTIF_TITLE"
            eww update notif_body="$NOTIF_BODY"
            
            # Now open it—it will display the fresh data instantly
            eww open notification_popup
            
            sleep 5
            
            eww close notification_popup
        ) &
    fi
done
