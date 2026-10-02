#!/bin/bash

print_status() {
    if pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -q "Mute: yes"; then
        echo 'MUTED'
    else
        echo 'UNMUTED'
    fi
}

print_status

pactl subscribe 2>/dev/null | grep --line-buffered "Event 'change' on source" | while read -r line; do
    print_status
done
