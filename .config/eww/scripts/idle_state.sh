#!/bin/bash
# idle_state.sh — "true" when hypridle awake mode is on, else "false".
# Mirrors the state file written by hypridle-toggle.sh (SUPER+I).
set -u

STATE="${XDG_RUNTIME_DIR:-/tmp}/hypridle-awake"
while true; do
  [[ -f "$STATE" ]] && echo "true" || echo "false"
  sleep 5
done
