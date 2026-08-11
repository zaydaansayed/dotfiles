#!/bin/bash

selected_file=$(fd --type f . "$HOME" --hidden --exclude .git --exclude .cache | fuzzel -d -w 80 -p "Select File > ")

if [[ -n "$selected_file" ]]; then
    current_paths=$(eww get ai_file_paths)
    
    if [[ -z "$current_paths" || "$current_paths" == "null" ]]; then
        current_paths="[]"
    fi

    updated_paths=$(jq --arg file "$selected_file" '. + [$file]' <<< "$current_paths")
    eww update ai_file_paths="$updated_paths"
fi
