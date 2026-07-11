#!/bin/bash

print_volume() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}'
}

print_volume

pactl subscribe | grep --line-buffered "Event 'change' on sink" | while read -r event; do
    print_volume
done
