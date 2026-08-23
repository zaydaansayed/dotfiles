#!/bin/bash

LIMIT=20

print_status() {
    local status="$1"
    local shuffle_status="$2"
    local loop_status="$3"
    local artist="$4"
    local title="$5"

    if [[ -z "$status" || -z "$title" ]]; then
        echo '{"text": "", "artist": "", "title": "", "icon": "", "shuffle_icon": "", "repeat_icon": "", "visible": false}'
        return
    fi

    # Escape quotes for valid JSON
    artist=$(echo "$artist" | sed 's/"/\\"/g')
    title=$(echo "$title" | sed 's/"/\\"/g')

    if [[ -z "$artist" ]]; then
        local text="$title"
    else
        local text="$artist - $title"
    fi

    local icon="󰐊"
    [[ "$status" == "Playing" ]] && icon="󰏤"

    local shuffle_icon="󰒞"
    if [[ "$shuffle_status" == "On" ]] || [[ "$shuffle_status" == "true" ]] || [[ "$shuffle_status" == "1" ]]; then
        shuffle_icon="󰒝"
    fi

    local repeat_icon="󰑗"
    if [[ "$loop_status" == "Track" ]] || [[ "$loop_status" == "Single" ]]; then
        repeat_icon="󰑘"
    elif [[ "$loop_status" == "Playlist" ]]; then
        repeat_icon="󰑖"
    fi

    echo "{\"text\": \"$text\", \"artist\": \"$artist\", \"title\": \"$title\", \"icon\": \"$icon\", \"shuffle_icon\": \"$shuffle_icon\", \"repeat_icon\": \"$repeat_icon\", \"visible\": true}"
}

# Initial trigger when script starts
if playerctl -l 2>/dev/null >/dev/null; then
    print_status \
        "$(playerctl status 2>/dev/null)" \
        "$(playerctl shuffle 2>/dev/null)" \
        "$(playerctl loop 2>/dev/null)" \
        "$(playerctl metadata --format "{{ artist }}" 2>/dev/null)" \
        "$(playerctl metadata --format "{{ title }}" 2>/dev/null)"
else
    echo '{"text": "", "artist": "", "title": "", "icon": "", "shuffle_icon": "", "repeat_icon": "", "visible": false}'
fi

# Live event stream loop
playerctl metadata --follow --format "{{ status }}|{{ shuffle }}|{{ loop }}|{{ artist }}|{{ title }}" 2>/dev/null | while IFS='|' read -r status shuffle loop artist title; do
    print_status "$status" "$shuffle" "$loop" "$artist" "$title"
done

