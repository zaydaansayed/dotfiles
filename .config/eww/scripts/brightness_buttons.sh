#!/usr/bin/env bash

LOCKFILE="/tmp/brightness_timer.pid"

if eww active-windows | grep -q "brightness"; then
    if [ -f "$LOCKFILE" ]; then
        OLD_PID=$(cat "$LOCKFILE")
        kill "$OLD_PID" 2>/dev/null
    fi
else
    
    eww open brightness 2>/dev/null
fi

(
    sleep 3
    eww close brightness 2>/dev/null
    rm -f "$LOCKFILE"
) &

echo $! > "$LOCKFILE"
