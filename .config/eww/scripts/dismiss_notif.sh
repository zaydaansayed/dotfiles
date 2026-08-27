#!/bin/bash

TARGET_ID="$1"

LATEST_ARRAY=$(eww get notifications_json)
UPDATED_ARRAY=$(echo "$LATEST_ARRAY" | jq --arg id "$TARGET_ID" 'del(.[] | select(.id == $id))')
eww update notifications_json="$UPDATED_ARRAY"

if [ "$UPDATED_ARRAY" = "[]" ]; then
    eww close notification_popup
fi
