#!/bin/bash

print_volume() {
  vol_output=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
  volume=$(echo "$vol_output" | awk '{printf "%.0f", $2 * 100}')
  [[ "$volume" =~ ^[0-9]+$ ]] || volume=0

  if [[ "$vol_output" == *"[MUTED]"* ]]; then
    muted="MUTED"
  else
    muted="UNMUTED"
  fi

  filled=$(( volume * 10 / 100 ))
  (( filled < 0 )) && filled=0
  (( filled > 10 )) && filled=10
  empty=$(( 10 - filled ))
  bar=""
  for ((i=0;i<filled;i++)); do bar+="█"; done
  for ((i=0;i<empty;i++)); do bar+="░"; done

  jq -nc --argjson volume "$volume" --arg vol_status "$muted" --arg bar "$bar" \
    '{"volume": $volume, "vol_status": $vol_status, "bar": $bar}'
}

print_volume

pactl subscribe | grep --line-buffered -E "Event 'change' on (sink|server)" | while read -r event; do
    print_volume
done
