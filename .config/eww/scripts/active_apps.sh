#!/bin/bash

declare -A ICON_CACHE

get_icon() {
  local lookup="$1"
  if [[ -n "${ICON_CACHE[$lookup]}" ]]; then
    echo "${ICON_CACHE[$lookup]}"
    return
  fi

  local desktop_file
  desktop_file=$(find /usr/share/applications/ ~/.local/share/applications/ -type f -iname "*${lookup}*.desktop" 2>/dev/null | head -n 1)

  local icon_name="$lookup"
  if [[ -n "$desktop_file" ]]; then
    icon_name=$(awk -F= '/^Icon=/ {print $2; exit}' "$desktop_file")
  fi

  ICON_CACHE["$lookup"]="${icon_name:-$lookup}"
  echo "${ICON_CACHE[$lookup]}"
}

active_apps() {
  local active_info
  active_info=$(hyprctl -j clients)
  local active_win
  active_win=$(hyprctl -j activewindow)
  local focused_pid
  focused_pid=$(echo "$active_win" | jq -r '.pid // -1')
  local workspace_windows
  workspace_windows=$(hyprctl -j activeworkspace | jq -r '.windows')

  local raw_apps
  raw_apps=$(echo "$active_info" | jq -c '.[] | {pid: .pid, title: .title, lookup: ((.initialClass // .class) | ascii_downcase)}')

  local app_list="[]"
  while read -r row; do
    [[ -z "$row" ]] && continue
    local pid lookup title
    pid=$(jq -r '.pid' <<< "$row")
    title=$(jq -r '.title' <<< "$row")
    lookup=$(jq -r '.lookup' <<< "$row")

    case "$lookup" in
      *firefox*|*spotify*) continue ;;
    esac

    local icon
    icon=$(get_icon "$lookup")
    local is_focused=false
    [[ "$pid" -eq "$focused_pid" ]] && is_focused=true

    app_list=$(jq -c --argjson list "$app_list" \
                    --argjson pid "$pid" \
                    --arg title "$title" \
                    --arg icon "$icon" \
                    --argjson focused "$is_focused" \
                    '$list + [{"pid":$pid, "title":$title, "icon":$icon, "focused":$focused}]' <<< {})
  done <<< "$raw_apps"

  jq -nc --argjson apps "$app_list" --argjson windows "$workspace_windows" \
    '{"apps": $apps, "workspace_windows": $windows}'
}

active_apps

socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | \
  grep --line-buffered -E "openwindow|closewindow|activewindow|workspace|movewindow" | \
  while read -r _; do
    active_apps
  done
