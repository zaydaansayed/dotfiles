#!/bin/bash

LIMIT=20

print_status() {
    local status="$1"
    local shuffle_status="$2"
    local loop_status="$3"
    
    local artist
    artist=$(playerctl metadata --format "{{ artist }}" 2>/dev/null)
    local title
    title=$(playerctl metadata --format "{{ title }}" 2>/dev/null)

    if [[ -z "$status" || -z "$title" ]]; then
        echo '{"text": "", "icon": "", "shuffle_icon": "", "repeat_icon": "", "visible": false}'
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

    local shuffle_icon="󰒞"
    if [[ "$shuffle_status" == "On" ]] || [[ "$shuffle_status" == "true" ]] || [[ "$shuffle_status" == "1" ]]; then
        shuffle_icon="󰒝"
    fi

    local repeat_icon="󰑗"
    if [[ "$loop_status" == "Track" ]] || [[ "$loop_status" == "Single" ]]; then
        repeat_icon="󰑘"
    elif [[ "$loop_status" == "Playlist" ]] || [[ "$loop_status" == "Playlist" ]]; then
        repeat_icon="󰕇"
    fi

    echo "{\"text\": \"$text\", \"icon\": \"$icon\", \"shuffle_icon\": \"$shuffle_icon\", \"repeat_icon\": \"$repeat_icon\", \"visible\": true}"
}

if playerctl -l 2>/dev/null ; then
    print_status "$(playerctl status 2>/dev/null)" "$(playerctl shuffle 2>/dev/null)" "$(playerctl loop 2>/dev/null)"
else
    echo '{"text": "", "icon": "", "shuffle_icon": "", "repeat_icon": "", "visible": false}'
fi

playerctl metadata --follow --format "{{ status }}|{{ shuffle }}|{{ loop }}" 2>/dev/null | while IFS='|' read -r status shuffle loop; do
    print_status "$status" "$shuffle" "$loop"
done
