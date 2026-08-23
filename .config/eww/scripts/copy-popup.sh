#!/usr/bin/env bash

LOCKFILE="/tmp/copy_timer.pid"

if eww active-windows | grep -q "copy-popup"; then
    if [ -f "$LOCKFILE" ]; then
        OLD_PID=$(cat "$LOCKFILE")
        kill "$OLD_PID" 2>/dev/null
    fi
else 
    eww open copy-popup 2>/dev/null
fi

(
    sleep 3
    eww close copy-popup 2>/dev/null
    rm -f "$LOCKFILE"
) &

echo $! > "$LOCKFILE"
