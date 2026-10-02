#!/bin/bash
cava -p ~/.config/cava/eww_config | while read -r line; do
    echo "$line" | sed 's/;/,/g' | sed 's/,$//' | awk '{print "[" $0 "]"}'
done
