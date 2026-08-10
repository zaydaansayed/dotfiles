#!/bin/bash

CHAT_ID="$1"
NEW_TITLE="$2"
INDEX_FILE="/home/zaydaansayed/Documents/ai_chats/index.json"

if [ -n "$CHAT_ID" ] && [ -n "$NEW_TITLE" ] && [ -f "$INDEX_FILE" ]; then
    jq --arg id "$CHAT_ID" --arg title "$NEW_TITLE" \
       'map(if .id == $id then .title = $title else . end)' \
       "$INDEX_FILE" > "${INDEX_FILE}.tmp" && mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
fi

eww update ai_menu_chats="$(cat /home/zaydaansayed/Documents/ai_chats/index.json 2>/dev/null || echo '[]')"
