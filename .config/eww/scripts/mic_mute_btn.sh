#!/usr/bin/env bash

LOCKFILE="/tmp/mic_timer.pid"

if eww active-windows | grep -q "mic_status"; then
    if [ -f "$LOCKFILE" ]; then
        OLD_PID=$(cat "$LOCKFILE")
        kill "$OLD_PID" 2>/dev/null
    fi
else 
    eww open --no-daemonize mic_status 2>/dev/null
fi

(
    sleep 3
    eww close mic_status 2>/dev/null
    rm -f "$LOCKFILE"
) &

echo $! > "$LOCKFILE"
