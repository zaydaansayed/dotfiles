#!/bin/bash

selected_file=$(fd --type f . "$HOME" --hidden --exclude .git --exclude .cache | fuzzel -d -w 80 -p "Select File > ")

if [[ -n "$selected_file" ]]; then
    current_paths=$(eww get localsend_files)
    
    if [[ -z "$current_paths" || "$current_paths" == "null" ]]; then
        current_paths="[]"
    fi

    updated_paths=$(jq --arg file "$selected_file" '. + [$file]' <<< "$current_paths")
    eww update localsend_files="$updated_paths"
fi
