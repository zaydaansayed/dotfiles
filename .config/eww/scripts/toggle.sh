#!/bin/bash
# toggle.sh — atomic eww window toggle, source of truth = active-windows.
# Usage: toggle.sh <window_name> [bool_var]
# Avoids desync from boolean vars going stale after hoverlost/Escape/reload.
# Returns 0 always so `&&` chains never break the close.
set -u
WIN="${1:-}"
VAR="${2:-}"
[[ -z "$WIN" ]] && { echo "usage: toggle.sh <window> [var]" >&2; exit 1; }

is_open() { eww active-windows 2>/dev/null | grep -q ": $WIN\$"; }

if is_open; then
  eww close "$WIN" 2>/dev/null || true
  [[ -n "$VAR" ]] && eww update "$VAR=false" 2>/dev/null || true
else
  eww open --no-daemonize "$WIN" 2>/dev/null || true
  [[ -n "$VAR" ]] && eww update "$VAR=true" 2>/dev/null || true
fi
exit 0
