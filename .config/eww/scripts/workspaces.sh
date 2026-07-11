#!/bin/bash

hyprctl activeworkspace | grep "workspace ID" | awk '{print $3}'

socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    if echo "$line" | grep -q "^workspace>>"; then
        echo "$line" | cut -d'>' -f3
    fi
done
