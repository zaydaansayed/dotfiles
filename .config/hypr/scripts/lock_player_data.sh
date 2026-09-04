#!/bin/bash

artist=$(playerctl -p spotify metadata artist)
title=$(playerctl -p spotify metadata title)
status=$(playerctl status)

if [[ -z "$artist" ]]; then
    text="$title"
else
    text="$artist - $title"
fi

if [[ $status == "Playing" ]]; then
	icon="󰏤"
elif [[ $status == "Paused" ]]; then
	icon="󰐊"
else 
	icon=""
fi

echo $text $icon
