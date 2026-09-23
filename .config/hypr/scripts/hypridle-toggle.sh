#!/bin/bash
# hypridle-toggle.sh — toggle between normal (auto dim + lock) and awake
# (no auto dim/lock) mode. Restarts hypridle with the matching config.
# State: $XDG_RUNTIME_DIR/hypridle-awake (present = awake mode).
set -u

NORMAL="$HOME/.config/hypr/hypridle.conf"
AWAKE="$HOME/.config/hypr/hypridle-awake.conf"
STATE="${XDG_RUNTIME_DIR:-/tmp}/hypridle-awake"

restart_hypridle() {
  pkill -x hypridle 2>/dev/null || true
  sleep 0.5
  # Kill stragglers, then start detached so it survives this script.
  pkill -9 -x hypridle 2>/dev/null || true
  setsid nohup hypridle -c "$1" >/dev/null 2>&1 < /dev/null &
  disown 2>/dev/null || true
}

if [[ -f "$STATE" ]]; then
  restart_hypridle "$NORMAL"
  rm -f "$STATE"
  notify-send "Hypridle" "Auto dim + lock ON" 2>/dev/null || true
  echo "normal"
else
  restart_hypridle "$AWAKE"
  touch "$STATE"
  notify-send "Hypridle" "Awake mode ON — no auto dim/lock" 2>/dev/null || true
  echo "awake"
fi
