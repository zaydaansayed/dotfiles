#!/bin/bash

active_apps() {
  focused_pid=$(hyprctl activewindow -j | jq -r '.pid // -1')

  hyprctl clients -j | jq -c '.[] | {pid: .pid, title: .title, lookup: (.initialClass // .class)}' | while read -r row; do
    [ -z "$row" ] && continue

    pid=$(echo "$row" | jq -r '.pid')
    title=$(echo "$row" | jq -r '.title')
    lookup=$(echo "$row" | jq -r '.lookup' | tr '[:upper:]' '[:lower:]')
    
    desktop_file=$(find /usr/share/applications/ ~/.local/share/applications/ -type f -iname "*${lookup}*.desktop" 2>/dev/null | head -n 1)

    if [ -n "$desktop_file" ]; then
      icon_name=$(awk -F= '/^Icon=/ {print $2; exit}' "$desktop_file")
    else
      icon_name="$lookup"
    fi

     is_focused="false"
    [ "$pid" -eq "$focused_pid" ] && is_focused="true"

    jq -nc --argjson pid "$pid" --arg title "$title" --arg icon "$icon_name" --argjson focused "$is_focused" \
      '{"pid":$pid, "title":$title, "icon":$icon, "focused":$focused}'
  done | jq -c -s .
}

active_apps

socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | \
  grep --line-buffered -E "openwindow|closewindow|activewindow" | \
  while read -r event; do
    active_apps
done

