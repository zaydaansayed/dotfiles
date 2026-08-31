#!/bin/bash

LIMIT=20

hex_to_rgb() {
    local hex="${1#\#}"
    local r=$(printf "%d" "0x${hex:0:2}")
    local g=$(printf "%d" "0x${hex:2:2}")
    local b=$(printf "%d" "0x${hex:4:2}")
    echo "$r, $g, $b"
}

update_colors() {
    if [[ -f /tmp/cover.png ]]; then
        mapfile -t colors < <(wallust run -s --print-scheme /tmp/cover.png 2>/dev/null)
        
        if [[ ${#colors[@]} -ge 16 ]]; then
            local raw_bg="${colors[0]}"
            local rgb_bg=$(hex_to_rgb "$raw_bg")
            local bg_color="rgba(${rgb_bg}, 0.5)"
            local text_color="${colors[7]}"

            eww update player_bg="$bg_color" player_text="$text_color" 2>/dev/null
        fi
    fi
}

print_status() {
    local status="$1"
    local shuffle_status="$2"
    local loop_status="$3"
    local artist="$4"
    local title="$5"

    if [[ -z "$status" || -z "$title" ]]; then
        echo '{"text": "", "artist": "", "title": "", "icon": "", "shuffle_icon": "", "repeat_icon": "", "visible": false}'
	eww close music_player_window
        return
    fi

    artist=$(echo "$artist" | sed 's/"/\\"/g')
    title=$(echo "$title" | sed 's/"/\\"/g')
    art_url=$(playerctl -p spotify metadata mpris:artUrl 2>/dev/null)
    
    if [[ -z "$art_url" ]]; then
       image=none
    else
      if [[ "$art_url" =~ ^https?:// ]]; then
        curl -s "$art_url" -o /tmp/cover.png
	image=/tmp/cover.png
      elif [[ "$art_url" =~ ^file:// ]]; then
        cp "${art_url#file://}" /tmp/cover.png
	image=/tmp/cover.png
      fi
    fi

    update_colors

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

    echo "{\"text\": \"$text\", \"artist\": \"$artist\", \"title\": \"$title\", \"icon\": \"$icon\", \"shuffle_icon\": \"$shuffle_icon\", \"repeat_icon\": \"$repeat_icon\", \"image\": \"$image\", \"visible\": true}"
}

if playerctl -p spotify status 2>/dev/null >/dev/null; then
    print_status \
        "$(playerctl -p spotify status 2>/dev/null)" \
        "$(playerctl -p spotify shuffle 2>/dev/null)" \
        "$(playerctl -p spotify loop 2>/dev/null)" \
        "$(playerctl -p spotify metadata --format "{{ artist }}" 2>/dev/null)" \
        "$(playerctl -p spotify metadata --format "{{ title }}" 2>/dev/null)"
else
    echo '{"text": "", "artist": "", "title": "", "icon": "", "shuffle_icon": "", "repeat_icon": "", "image": "none", "visible": false}'
fi

playerctl -p spotify metadata --follow --format "{{ status }}|{{ shuffle }}|{{ loop }}|{{ artist }}|{{ title }}" 2>/dev/null | while IFS='|' read -r status shuffle loop artist title; do
    print_status "$status" "$shuffle" "$loop" "$artist" "$title"
done
