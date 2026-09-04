#!/bin/bash

LIMIT=20
LAST_ART_URL=""

hex_to_rgb() {
    local hex="${1#\#}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "$r, $g, $b"
}

update_colors() {
    if [[ -f /tmp/cover.png ]]; then
        mapfile -t colors < <(wallust run -s --print-scheme /tmp/cover.png 2>/dev/null)
        
        if [[ ${#colors[@]} -ge 16 ]]; then
            local raw_bg="${colors[0]}"
            local rgb_bg
            rgb_bg=$(hex_to_rgb "$raw_bg")
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
	eww update music_toggle=false 2>/dev/null
        eww close music_player_window 2>/dev/null
        return
    fi

    artist="${artist//\"/\\\"}"
    title="${title//\"/\\\"}"
    
    local art_url
    art_url=$(playerctl -p spotify metadata mpris:artUrl 2>/dev/null)
    local image="none"

    if [[ -n "$art_url" ]]; then
        image=/tmp/cover.png
        if [[ "$art_url" != "$LAST_ART_URL" ]]; then
            LAST_ART_URL="$art_url"
            if [[ "$art_url" =~ ^https?:// ]]; then
                curl -s "$art_url" -o /tmp/cover.png
            elif [[ "$art_url" =~ ^file:// ]]; then
                cp "${art_url#file://}" /tmp/cover.png
            fi
            update_colors
        fi
    fi

    local text
    if [[ -z "$artist" ]]; then
        text="$title"
    else
        text="$artist - $title"
    fi

    local icon="󰐊"
    [[ "$status" == "Playing" ]] && icon="󰏤"

    local shuffle_icon="󰒞"
    if [[ "$shuffle_status" == "On" || "$shuffle_status" == "true" || "$shuffle_status" == "1" ]]; then
        shuffle_icon="󰒝"
    fi

    local repeat_icon="󰑗"
    if [[ "$loop_status" == "Track" || "$loop_status" == "Single" ]]; then
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
