#!/bin/bash

eww update ai_loading=true
mkdir -p /home/zaydaansayed/Documents

prompt=$(eww get ai_prompt)
file_paths=$(eww get ai_file_paths)
dynamic_context=$(eww get ai_dynamic_context 2>/dev/null || echo "")

# If no chat is active, generate a unique ID for this new thread
chat_id=$(eww get ai_chat_id 2>/dev/null)
if [ -z "$chat_id" ]; then
  chat_id="chat_$(date +%s)"
  eww update ai_chat_id="$chat_id"
fi

/home/zaydaansayed/venv/bin/python /home/zaydaansayed/dotfiles/local-web-ai/ai.py \
  "$prompt" "$file_paths" "$dynamic_context" "$chat_id"

eww update ai_loading=false
eww update ai_dinput=""
eww update ai_file_paths="[]"
