#!/bin/bash
# workspaces_list.sh — JSON array of workspace ids greater than 5 (for dynamic bar buttons).
# Prints once, then re-prints on Hyprland events (deflisten mode).
# Shape: [6, 7, ...] (empty array when no workspace above 5 exists)
set -u

emit() {
  hyprctl -j workspaces 2>/dev/null | jq -c 'map(.id) | sort | map(select(. > 5))'
}

emit

socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" 2>/dev/null | while read -r line; do
  case "$line" in
    workspace*|openwindow*|closewindow*|movewindow*|moveworkspace*)
      emit
      ;;
  esac
done
