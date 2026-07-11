#!/bin/bash

LIMIT=20

print_status() {
    local status="$1"
    local artist="$2"
    local title="$3"

    if [[ -z "$status" || -z "$title" ]]; then
        echo '{"text": "", "icon": "", "visible": false}'
        return
    fi

    artist=$(echo "$artist" | sed 's/"/\\"/g')
    title=$(echo "$title" | sed 's/"/\\"/g')

    if [[ -z "$artist" ]]; then
        local full_text="$title"
    else
        local full_text="$artist - $title"
    fi

    if [ ${#full_text} -gt $LIMIT ]; then
        local text="${full_text:0:$((LIMIT-3))}..."
    else
        local text="$full_text"
    fi

    local icon="󰐊"
    [[ "$status" == "Playing" ]] && icon="󰏤"

    echo "{\"text\": \"$text\", \"icon\": \"$icon\", \"visible\": true}"
}

if playerctl -l 2>/dev/null | grep -q "spotify"; then
    print_status "$(playerctl --player=spotify status 2>/dev/null)" \
                 "$(playerctl --player=spotify metadata --format "{{ artist }}" 2>/dev/null)" \
                 "$(playerctl --player=spotify metadata --format "{{ title }}" 2>/dev/null)"
else
    echo '{"text": "", "icon": "", "visible": false}'
fi

playerctl --player=spotify metadata --follow --format "{{ status }}|{{ artist }}|{{ title }}" 2>/dev/null | while IFS='|' read -r status artist title; do
    print_status "$status" "$artist" "$title"
done
