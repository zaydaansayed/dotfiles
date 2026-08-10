#!/bin/bash

eww update ai_loading=true

CHAT_DIR="/home/zaydaansayed/Documents/ai_chats"
INDEX_FILE="$CHAT_DIR/index.json"
mkdir -p "$CHAT_DIR"

if [ ! -f "$INDEX_FILE" ]; then
    echo "[]" > "$INDEX_FILE"
fi

prompt=$(eww get ai_prompt)
file_paths=$(eww get ai_file_paths)
chat_id=$(eww get ai_chat_id 2>/dev/null)

if [ -z "$chat_id" ]; then
    chat_id="chat_$(date +%s)"
    eww update ai_chat_id="$chat_id"
fi

CHAT_FILE="$CHAT_DIR/${chat_id}.json"

if [ ! -f "$CHAT_FILE" ]; then
    echo "[]" > "$CHAT_FILE"
    
    title=$(ollama run qwen2.5:1.5b "Summarize this prompt in 3 to 5 words as a short title. Return ONLY the title with no quotes, formatting, or period: $prompt" 2>/dev/null)
    if [ -z "$title" ]; then title="New Chat"; fi
    
    jq --arg id "$chat_id" --arg title "$title" '. + [{"id": $id, "title": $title}]' "$INDEX_FILE" > "${INDEX_FILE}.tmp" && mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
fi

history_json=$(cat "$CHAT_FILE")

response=$(/home/zaydaansayed/venv/bin/python /home/zaydaansayed/dotfiles/.config/scripts/Isaac-ai/ai.py \
  "$prompt" "$file_paths" "$history_json")

attachments_json=$(echo "$file_paths" | jq -c . 2>/dev/null || echo '[]')

jq --arg prompt "$prompt" --argjson response "$response" --argjson attachments "$attachments_json" \
   '. + [{"prompt": $prompt, "response": $response, "attachments": $attachments}]' "$CHAT_FILE" > "${CHAT_FILE}.tmp" && mv "${CHAT_FILE}.tmp" "$CHAT_FILE"

eww update ai_loading=false
eww update ai_dinput=""
eww update ai_file_paths="[]"
