#!/bin/bash
CONF="$HOME/dotfiles/.config/eww/scripts"

esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

prompt_mode() {
  local ssid="$1" e
  e=$(esc "$ssid")
  eww update sysnotif_type="input"
  eww update sysnotif_text_input=""
  eww update "sysnotif_text_main=Password for $e"
  eww update "sysnotif_commandia=$CONF/wifi_connect.sh \"$e\" \"{}\" &"
  eww open system_notification
}

connect_mode() {
  local ssid="$1" pass="$2" out code err
  if [[ -z "$pass" ]]; then
    out=$(nmcli dev wifi connect "$ssid" 2>&1)
  else
    out=$(nmcli dev wifi connect "$ssid" password "$pass" 2>&1)
  fi
  code=$?
  if [[ $code -eq 0 ]]; then
    eww close system_notification
  else
    err=$(printf '%s' "$out" | head -n1 | cut -c1-80)
    eww update sysnotif_type="information"
    eww update "sysnotif_text_main=Failed to connect to \"$(esc "$ssid")\": $(esc "$err")"
    eww update "sysnotif_text_butl=Retry"
    eww update "sysnotif_text_butr=Dismiss"
    eww update "sysnotif_commandbl=$CONF/wifi_connect.sh --prompt \"$(esc "$ssid")\" &"
    eww update sysnotif_commandbr="eww close system_notification"
    eww open system_notification
  fi
}

case "$1" in
  --prompt) prompt_mode "$2" ;;
  --disconnect) nmcli con down id "$2" 2>/dev/null || nmcli dev disconnect 2>/dev/null ;;
  --rescan) nmcli dev wifi rescan 2>/dev/null ;;
  *) connect_mode "$1" "$2" ;;
esac
