#!/bin/bash
# hypr_state.sh — deflisten: event-driven Hyprland state (was a 3s defpoll).
# Refresh triggers: USR1 from hypr_set.sh after every change, Hyprland
# socket2 config/monitor events, 30s freshness fallback.

LAST_OUTPUT=""
TRIG=/tmp/eww_hypr_state.trigger

hypr_socket() {
  local dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr"
  local sig="$HYPRLAND_INSTANCE_SIGNATURE"
  if [[ -n "$sig" && -S "$dir/$sig/.socket2.sock" ]]; then
    echo "$dir/$sig/.socket2.sock"; return
  fi
  ls -t "$dir"/*/.socket2.sock 2>/dev/null | head -n1
}

opt_int()   { hyprctl getoption "$1" -j 2>/dev/null | jq -r '.int // 0'; }
opt_float() { hyprctl getoption "$1" -j 2>/dev/null | jq -r '.float // 0'; }
opt_bool()  { hyprctl getoption "$1" -j 2>/dev/null | jq -r '.bool // false'; }

emit() {
gaps_in=$(hyprctl getoption general:gaps_in -j 2>/dev/null | jq -r '(.css // "0") | split(" ")[0] | tonumber? // 0')
gaps_out=$(hyprctl getoption general:gaps_out -j 2>/dev/null | jq -r '(.css // "0") | split(" ")[0] | tonumber? // 0')

mon=$(hyprctl monitors -j 2>/dev/null | jq '{monitor: (.[0].name // ""), scale: (.[0].scale // 1)}')
cursor_size=$(grep -oP 'XCURSOR_SIZE",\s*"\K[0-9]+' "$HOME/dotfiles/.config/hypr/modules/env_variables.lua" 2>/dev/null || echo 24)
gtk_theme=$(grep -oP 'GTK_THEME",\s*"\K[^"]+' "$HOME/dotfiles/.config/hypr/modules/env_variables.lua" 2>/dev/null || echo "Adwaita-dark")
hide_logo=true
grep -q 'disable_hyprland_logo\s*=\s*false' "$HOME/dotfiles/.config/hypr/modules/misc.lua" 2>/dev/null && hide_logo=false

autostart=$(grep -n 'hl\.exec_cmd' "$HOME/dotfiles/.config/hypr/modules/autostart.lua" 2>/dev/null \
  | sed -E 's/^([0-9]+):[[:space:]]*(--)?[[:space:]]*hl\.exec_cmd\("(.*)"\)[^"]*$/\1|\2|\3/' \
  | jq -R -s '
      split("\n") | map(select(length > 0)) |
      map(split("|") | {line: (.[0] | tonumber), cmd: .[2],
                        enabled: (.[1] != "--")})')

new_output=$(jq -nc \
  --argjson gaps_in "${gaps_in:-0}" --argjson gaps_out "${gaps_out:-0}" \
  --argjson border_size "$(opt_int general:border_size)" \
  --argjson rounding "$(opt_int decoration:rounding)" \
  --argjson active_op "$(opt_float decoration:active_opacity)" \
  --argjson inactive_op "$(opt_float decoration:inactive_opacity)" \
  --argjson blur "$(opt_bool decoration:blur:enabled)" \
  --argjson shadow "$(opt_bool decoration:shadow:enabled)" \
  --argjson anims "$(opt_bool animations:enabled)" \
  --argjson tearing "$(opt_bool general:allow_tearing)" \
  --argjson sens "$(opt_float input:sensitivity)" \
  --argjson nat_scroll "$(opt_bool input:touchpad:natural_scroll)" \
  --argjson tap_click "$(opt_bool input:touchpad:tap_to_click)" \
  --argjson mon "$mon" --arg cursor_size "$cursor_size" --arg gtk_theme "$gtk_theme" \
  --argjson hide_logo "$hide_logo" \
  --argjson autostart "${autostart:-[]}" \
  '{gaps_in: $gaps_in, gaps_out: $gaps_out, border_size: $border_size,
    rounding: $rounding,
    active_op: (($active_op * 100) | round), inactive_op: (($inactive_op * 100) | round),
    blur: $blur, shadow: $shadow, anims: $anims, tearing: $tearing,
    sens: (($sens * 100) | round),
    nat_scroll: $nat_scroll, tap_click: $tap_click,
    monitor: $mon.monitor, scale: $mon.scale,
    cursor_size: ($cursor_size | tonumber? // 24), gtk_theme: $gtk_theme,
    hide_logo: $hide_logo,
    autostart: $autostart}')
  if [[ "$new_output" != "$LAST_OUTPUT" ]]; then
    echo "$new_output"
    LAST_OUTPUT="$new_output"
  fi
}

emit  # initial

# socket2 monitor: lua edits + `hyprctl reload`, monitor hotplug
(
  while true; do
    sock=$(hypr_socket)
    if [[ -n "$sock" ]]; then
      socat -U - "UNIX-CONNECT:$sock" 2>/dev/null \
        | grep --line-buffered -E 'configreloaded|monitoradded|monitorremoved' \
        | while read -r _; do touch "$TRIG" 2>/dev/null; done
    fi
    sleep 10
  done
) &

# event loop: 1s stat checks (near-zero cost), full refresh every 30 ticks,
# re-emits rate-limited to ~1/sec so slider drags don't fight live updates
touch "$TRIG"
last=$(stat -c %Y "$TRIG" 2>/dev/null || echo 0)
tick=0
last_emit=0
pending=false
while true; do
  sleep 0.5
  tick=$((tick + 1))
  cur=$(stat -c %Y "$TRIG" 2>/dev/null || echo 0)
  [[ "$cur" != "$last" ]] && { last=$cur; pending=true; }
  now=${EPOCHREALTIME%.*}
  if [[ "$pending" == true || $tick -ge 60 ]] && [[ $now -gt $last_emit ]]; then
    last_emit=$now
    pending=false
    tick=0
    emit
  fi
done
