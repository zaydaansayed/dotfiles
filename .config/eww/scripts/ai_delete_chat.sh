#!/bin/bash
CHAT_ID="$1"
INDEX_FILE="/home/zaydaansayed/Documents/ai_chats/index.json"
CHAT_FILE="/home/zaydaansayed/Documents/ai_chats/${CHAT_ID}.json"

rm -f "$CHAT_FILE"

if [ -f "$INDEX_FILE" ]; then
    jq --arg id "$CHAT_ID" 'del(.[] | select(.id == $id))' "$INDEX_FILE" > "${INDEX_FILE}.tmp" \
        && mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
fi

eww update ai_menu_chats="$(cat "$INDEX_FILE" 2>/dev/null || echo '[]')"

CURRENT_CHAT=$(eww get ai_chat_id)
if [ "$CURRENT_CHAT" = "$CHAT_ID" ]; then
    eww update ai_chat_id=""
    eww update ai_txt="[]"
fi
