#!/bin/bash

prompt=$(eww get ai_prompt)
output_file="/home/zaydaansayed/Documents/.ai.txt"

raw_api_response=$(curl -s http://localhost:11434/api/generate \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg p "$prompt" '{model: "tinyllama", prompt: $p, stream: false}')")

ai_text=$(echo "$raw_api_response" | jq -r '.response // empty')

[[ -z "$ai_text" ]] && { eww update ai_loading=false; exit 1; }

if [[ ! -f "$output_file" ]] || [[ $(cat "$output_file" 2>/dev/null) == "empty" ]] || [[ ! -s "$output_file" ]]; then
    echo "[]" > "$output_file"
fi

new_entry=$(jq -n --arg res "$ai_text" --arg pr "$prompt" '{response: $res, prompt: $pr}')

updated_json=$(jq --argjson item "$new_entry" '. + [$item]' "$output_file")
echo "$updated_json" > "$output_file"

eww update ai_loading=false
