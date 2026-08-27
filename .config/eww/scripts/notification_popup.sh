#!/bin/bash

eww update notifications_json="[]"

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
        
        NOTIF_ID=$(date +%s%N)

        CURRENT_ARRAY=$(eww get notifications_json)
        NEW_ARRAY=$(echo "$CURRENT_ARRAY" | jq --arg app "$APP_NAME" \
                                              --arg title "$NOTIF_TITLE" \
                                              --arg body "$NOTIF_BODY" \
                                              --arg id "$NOTIF_ID" \
                   '. += [{"id": $id, "app": $app, "title": $title, "body": $body}]')
        
        eww update notifications_json="$NEW_ARRAY"
        eww open notification_popup

        (
            sleep 5
            LATEST_ARRAY=$(eww get notifications_json)
            UPDATED_ARRAY=$(echo "$LATEST_ARRAY" | jq --arg id "$NOTIF_ID" 'del(.[] | select(.id == $id))')
            eww update notifications_json="$UPDATED_ARRAY"
            
            if [ "$UPDATED_ARRAY" = "[]" ]; then
                eww close notification_popup
            fi
        ) &
    fi
done

