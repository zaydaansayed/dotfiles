#!/bin/bash

declare -A ICON_MAP
declare -A ICON_CACHE

# 1. Build an index mapping StartupWMClass, app IDs, and binary names to GTK icon names
build_icon_index() {
  eval "$(python3 - << 'EOF'
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gio
import shlex

apps = Gio.AppInfo.get_all()
for app in apps:
    icon = app.get_icon()
    if not icon:
        continue

    icon_name = None
    if isinstance(icon, Gio.ThemedIcon):
        names = icon.get_names()
        if names:
            icon_name = names[0]
    elif isinstance(icon, Gio.FileIcon):
        icon_name = icon.get_file().get_basename()

    if not icon_name:
        continue

    keys = set()
    app_id = app.get_id()
    if app_id:
        clean_id = app_id.replace('.desktop', '').lower()
        keys.add(clean_id)
        if '.' in clean_id:
            keys.add(clean_id.split('.')[-1])

    wmclass = app.get_startup_wm_class()
    if wmclass:
        keys.add(wmclass.lower())

    exec_name = app.get_executable()
    if exec_name:
        keys.add(exec_name.lower())

    for key in keys:
        print(f'ICON_MAP[{shlex.quote(key)}]={shlex.quote(icon_name)}')
EOF
)"
}

build_icon_index

get_icon() {
  local lookup="$1"
  local clean_lookup
  clean_lookup=$(echo "$lookup" | tr '[:upper:]' '[:lower:]')

  if [[ -n "${ICON_CACHE[$clean_lookup]}" ]]; then
    echo "${ICON_CACHE[$clean_lookup]}"
    return
  fi

  local icon_name=""

  # 1. Match indexed desktop mappings
  if [[ -n "${ICON_MAP[$clean_lookup]}" ]]; then
    icon_name="${ICON_MAP[$clean_lookup]}"
  fi

  # 2. Try tail of reverse domain (e.g., com.obsproject.studio -> studio)
  if [[ -z "$icon_name" && "$clean_lookup" == *.* ]]; then
    local tail_name="${clean_lookup##*.}"
    [[ -n "${ICON_MAP[$tail_name]}" ]] && icon_name="${ICON_MAP[$tail_name]}"
  fi

  # 3. Explicit edge-case overrides
  if [[ -z "$icon_name" ]]; then
    case "$clean_lookup" in
      *obs*|*obsproject*) icon_name="com.obsproject.Studio" ;;
      *)                  icon_name="${clean_lookup##*.}" ;;
    esac
  fi

  ICON_CACHE["$clean_lookup"]="$icon_name"
  echo "$icon_name"
}

active_apps() {
  local active_info active_win focused_pid workspace_windows
  active_info=$(hyprctl -j clients)
  active_win=$(hyprctl -j activewindow)
  focused_pid=$(echo "$active_win" | jq -r '.pid // -1')
  workspace_windows=$(hyprctl -j activeworkspace | jq -r '.windows')

  local raw_apps
  raw_apps=$(echo "$active_info" | jq -c '.[] | {pid: .pid, title: .title, lookup: ((.initialClass // .class) | ascii_downcase)}')

  local app_list="[]"
  while read -r row; do
    [[ -z "$row" ]] && continue
    local pid lookup title icon is_focused=false
    pid=$(jq -r '.pid' <<< "$row")
    title=$(jq -r '.title' <<< "$row")
    lookup=$(jq -r '.lookup' <<< "$row")

    case "$lookup" in
      *firefox*|*spotify*) continue ;;
    esac

    icon=$(get_icon "$lookup")
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
