#!/bin/bash
# toggle.sh — atomic eww window toggle, source of truth = active-windows.
# Usage: toggle.sh <window_name> [bool_var]
# Avoids desync from boolean vars going stale after hoverlost/Escape/reload.
# Returns 0 always so `&&` chains never break the close.
set -u

WIN="${1:-}"
shift 1 || true

is_open() { eww active-windows 2>/dev/null | grep -q ": $WIN$"; }

if is_open; then
    eww close "$WIN" 2>/dev/null || true
    for var in "$@"; do
        eww update "$var=false" 2>/dev/null || true
    done
else
    eww open "$WIN" 2>/dev/null || true
    for var in "$@"; do
        eww update "$var=true" 2>/dev/null || true
    done
fi

exit 0
