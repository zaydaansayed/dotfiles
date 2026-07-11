#!/bin/bash

print_volume() {
  volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%.0f", $2 * 100}')
  status=$([ "$(pactl get-sink-mute @DEFAULT_SINK@)" = "Mute: yes" ] && echo "muted" || echo "unmuted")

  if [[ $volume -eq 0 ]]; then
      icon=""
  elif [[ $volume -le 25 ]]; then
      icon=" "
  else
      icon=" "
  fi

  if [[ $status == "muted" ]]; then
      icon=" "
  fi
  
  echo "$icon"
}

print_volume

pactl subscribe | grep --line-buffered "Event 'change' on sink" | while read -r event; do
    print_volume
done

