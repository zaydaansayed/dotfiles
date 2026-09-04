#!/bin/bash

declare -A ICON_MAP
declare -A ICON_CACHE

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

get_terminal_child_process() {
  local ppid="$1"
  local children_file="/proc/$ppid/task/$ppid/children"
  
  [[ ! -r "$children_file" ]] && return

  local child_pid
  child_pid=$(tr ' ' '\n' < "$children_file" | sort -n | tail -n 1)

  if [[ -n "$child_pid" && -r "/proc/$child_pid/comm" ]]; then
    local proc_name
    proc_name=$(< "/proc/$child_pid/comm")
    proc_name="${proc_name//[$'\t\r\n ']/}"

    if [[ "$proc_name" =~ ^(bash|zsh|fish|sh|kitten|kitty)$ ]]; then
      local sub_children_file="/proc/$child_pid/task/$child_pid/children"
      if [[ -r "$sub_children_file" ]]; then
        local sub_child
        sub_child=$(tr ' ' '\n' < "$sub_children_file" | sort -n | tail -n 1)
        if [[ -n "$sub_child" && -r "/proc/$sub_child/comm" ]]; then
          local sub_proc
          sub_proc=$(< "/proc/$sub_child/comm")
          echo "${sub_proc//[$'\t\r\n ']/}"
          return
        fi
      fi
    fi
    echo "$proc_name"
  fi
}

get_icon() {
  local lookup="$1"
  local title="$2"
  local pid="$3"
  local clean_lookup="${lookup,,}"
  local clean_title="${title,,}"

  case "$clean_lookup" in
    kitty|alacritty|foot|wezterm|st|xterm|org.wezfurlong.wezterm)
      local active_cmd=""
      if [[ -n "$pid" && "$pid" -gt 0 ]]; then
        active_cmd=$(get_terminal_child_process "$pid")
      fi

      if [[ -z "$active_cmd" || "$active_cmd" =~ ^(fish|bash|zsh|kitten)$ ]]; then
        case "$clean_title" in
          *nvim*|*neovim*) echo "kitty"; return ;;
          *yazi*)          active_cmd="yazi" ;;
          *btop*)          active_cmd="btop" ;;
          *htop*)          active_cmd="htop" ;;
          *ranger*)        active_cmd="ranger" ;;
          *tmux*)          active_cmd="tmux" ;;
        esac
      fi

      if [[ -n "$active_cmd" ]]; then
        local clean_cmd="${active_cmd,,}"
        if [[ -n "${ICON_MAP[$clean_cmd]}" ]]; then
          echo "${ICON_MAP[$clean_cmd]}"
          return
        fi
        echo "kitty"
        return
      fi

      echo "kitty"
      return
      ;;
  esac

  if [[ -n "${ICON_CACHE[$clean_lookup]}" ]]; then
    echo "${ICON_CACHE[$clean_lookup]}"
    return
  fi

  local icon_name=""

  if [[ -n "${ICON_MAP[$clean_lookup]}" ]]; then
    icon_name="${ICON_MAP[$clean_lookup]}"
  fi

  if [[ -z "$icon_name" && "$clean_lookup" == *.* ]]; then
    local tail_name="${clean_lookup##*.}"
    [[ -n "${ICON_MAP[$tail_name]}" ]] && icon_name="${ICON_MAP[$tail_name]}"
  fi

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

  local app_json_items=()

  while read -r row; do
    [[ -z "$row" ]] && continue
    local pid lookup title icon is_focused=false
    pid=$(jq -r '.pid' <<< "$row")
    title=$(jq -r '.title' <<< "$row")
    lookup=$(jq -r '.lookup' <<< "$row")

    case "$lookup" in
      *firefox*|*spotify*) continue ;;
    esac

    icon=$(get_icon "$lookup" "$title" "$pid")
    [[ "$pid" -eq "$focused_pid" ]] && is_focused=true

    local safe_title safe_icon
    safe_title=$(jq -aR . <<< "$title")
    safe_icon=$(jq -aR . <<< "$icon")
    
    app_json_items+=("{\"pid\":$pid,\"title\":$safe_title,\"icon\":$safe_icon,\"focused\":$is_focused}")
  done <<< "$raw_apps"

  local combined_apps
  combined_apps=$(IFS=,; echo "[${app_json_items[*]}]")
  
  jq -nc --argjson apps "$combined_apps" --argjson windows "$workspace_windows" \
    '{"apps": $apps, "workspace_windows": $windows}'
}

active_apps

while read -r _; do
  active_apps
done < <(socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | grep --line-buffered -E "openwindow|closewindow|activewindow|workspace")
