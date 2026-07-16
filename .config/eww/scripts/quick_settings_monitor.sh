#!/usr/bin/env bash

if ! command -v socat &> /dev/null; then
    echo "Error: 'socat' is required but not installed." >&2
    exit 1
fi

if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    SOCKET_PATH=$(find "$XDG_RUNTIME_DIR/hypr" -name ".socket2.sock" | head -n 1)
else
    SOCKET_PATH="$XDG_RUNTIME_DIR/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
fi

if [ -z "$SOCKET_PATH" ] || [ ! -S "$SOCKET_PATH" ]; then
    echo "Error: Could not locate Hyprland socket2.sock" >&2
    exit 1
fi

get_current_state() {
    if eww active-windows | grep -q "^quick_settings:"; then
        echo "open"
    else
        echo "closed"
    fi
}

LAST_STATE=$(get_current_state)
echo "$LAST_STATE"

while read -r line; do
    if [[ "$line" == "openlayer>>gtk-layer-shell" || "$line" == "closelayer>>gtk-layer-shell" ]]; then
        CURRENT_STATE=$(get_current_state)
        
        if [ "$CURRENT_STATE" != "$LAST_STATE" ]; then
            echo "$CURRENT_STATE"
            LAST_STATE="$CURRENT_STATE"
        fi
    fi
done < <(socat -u "UNIX-CONNECT:${SOCKET_PATH}" -)
