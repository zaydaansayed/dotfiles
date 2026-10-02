#!/bin/bash
cleanup() { jobs -p | xargs -r kill 2>/dev/null; pkill -P $$ 2>/dev/null; exit 0; }
trap cleanup EXIT TERM INT

PIDF=/tmp/eww_bt_scan.pid
EXPF=/tmp/eww_bt_scan.exp
LAST_OUTPUT=""

scan_active() {
  [[ -f "$PIDF" ]] || return 1
  local pid now exp
  pid=$(cat "$PIDF" 2>/dev/null)
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null || return 1
  now=$(date +%s); exp=$(cat "$EXPF" 2>/dev/null || echo 0)
  if [[ "$now" -gt "$exp" ]]; then
    kill "$pid" 2>/dev/null
    bluetoothctl scan off &>/dev/null
    rm -f "$PIDF" "$EXPF"
    return 1
  fi
  return 0
}

get_bt() {
    local bt_show devcname icon new_output bt_on=false scanning=false

    scan_active && scanning=true

    bt_show=$(bluetoothctl show 2>/dev/null)
    devcname=$(bluetoothctl devices Connected 2>/dev/null | cut -d ' ' -f 3- | paste -sd ", " -)

    if [[ "$bt_show" == *"Powered: yes"* ]]; then
        bt_on=true
        if [[ -n "$(bluetoothctl devices Connected 2>/dev/null)" ]]; then
            icon="󰂱"
        else
            icon=""
        fi
    else
        icon="󰂲"
    fi

    local devices="[]"
    if [[ "$bt_on" == true ]]; then
        devices=$(bluetoothctl devices 2>/dev/null | while read -r _ mac rest; do
          [[ -z "$mac" ]] && continue
          local info name paired connected nearby
          info=$(bluetoothctl info "$mac" 2>/dev/null)
          name=$(echo "$rest" | sed 's/^ *//')
          paired=false; connected=false; nearby=false
          echo "$info" | grep -q 'Paired: yes' && paired=true
          echo "$info" | grep -q 'Connected: yes' && connected=true
          echo "$info" | grep -q 'RSSI:' && nearby=true
          if [[ "$connected" == false && "$name" =~ ^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$ ]]; then
            continue
          fi
          jq -nc --arg mac "$mac" --arg name "$name" \
            --argjson paired "$paired" --argjson connected "$connected" \
            --argjson nearby "$nearby" \
            '{mac: $mac, name: $name, paired: $paired, connected: $connected, nearby: $nearby}'
        done | jq -s '.')
        [[ -z "$devices" ]] && devices="[]"
    fi

    new_output=$(jq -nc --arg icon "$icon" --arg devcname "$devcname" \
      --argjson bt_on "$bt_on" --argjson scanning "$scanning" --argjson devices "$devices" \
      '{icon: $icon, devcname: $devcname, bt_on: $bt_on, scanning: $scanning, devices: $devices}')

    if [[ "$new_output" != "$LAST_OUTPUT" ]]; then
        echo "$new_output"
        LAST_OUTPUT="$new_output"
    fi
}

get_bt

( gdbus monitor --system --dest org.bluez 2>/dev/null \
    | grep --line-buffered -E 'Connected|Powered|InterfacesAdded|InterfacesRemoved|RSSI' \
    | while read -r _; do sleep 0.5; get_bt; done ) &

while true; do
    sleep 10
    get_bt
done
