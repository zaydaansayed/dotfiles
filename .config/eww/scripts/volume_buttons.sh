#!/usr/bin/env bash

LOCKFILE="/tmp/volume_timer.pid"

if eww active-windows | grep -q "volume"; then
    if [ -f "$LOCKFILE" ]; then
        OLD_PID=$(cat "$LOCKFILE")
        kill "$OLD_PID" 2>/dev/null
    fi
else
    
    eww open volume 2>/dev/null
fi

(
    sleep 3
    eww close volume 2>/dev/null
    rm -f "$LOCKFILE"
) &

echo $! > "$LOCKFILE"
