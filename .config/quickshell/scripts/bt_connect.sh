#!/bin/bash
CONF="$HOME/dotfiles/.config/eww/scripts"
PIDF=/tmp/eww_bt_connect.pid

esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
strip() { sed -e 's/\x1b\[[0-9;]*[A-Za-z]//g' -e 's/\r//g' -e 's/\[bluetoothctl\]>//g'; }

connect_mode() {
  local mac="$1" name="${2:-$1}"
  echo $$ > "$PIDF"
  trap 'kill $COPROC_PID 2>/dev/null; rm -f "$PIDF"; exit 0' TERM INT

  eww update sysnotif_type="information"
  eww update "sysnotif_text_main=Connecting to \"$(esc "$name")\""
  eww update "sysnotif_text_butl=Cancel"
  eww update "sysnotif_text_butr=Dismiss"
  eww update "sysnotif_commandbl=kill $(cat "$PIDF" 2>/dev/null) 2>/dev/null; eww close system_notification"
  eww update sysnotif_commandbr="eww close system_notification"
  eww open --no-daemonize system_notification

  coproc BT { bluetoothctl 2>&1; }
  local bin=${BT[1]} bout=${BT[0]} buf="" chunk answered=false
  send() { printf '%s\n' "$1" >&"$bin"; }

  wait_for() {
    local ok="$1" bad="$2" deadline=$(( $(date +%s) + $3 ))
    answered=false
    while [[ $(date +%s) -lt $deadline ]]; do
      if IFS= read -r -t 1 -u "$bout" -n 128 chunk; then
        buf+="$chunk"
      fi
      local clean
      clean=$(printf '%s' "$buf" | strip)
      if [[ "$answered" == false && "$clean" =~ \(yes/no\) ]]; then
        send "yes"; answered=true
      fi
      if [[ "$clean" =~ $ok ]]; then
        return 0
      fi
      if [[ -n "$bad" && "$clean" =~ $bad ]]; then
        return 1
      fi
    done
    return 2
  }

  finish_fail() {
    send "quit" 2>/dev/null
    wait "$BT_PID" 2>/dev/null
    trap - TERM INT
    rm -f "$PIDF"
    local err clean
    clean=$(printf '%s' "$buf" | strip \
      | sed -E 's/(agent on|default-agent|pairable on|pair [0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}|trust [0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}|connect [0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}|scan (on|off)|quit)//g' \
      | grep -v -E '^\s*$|Waiting to connect|Agent registered|Agent is already|Changing .* succeeded|SupportedUUIDs|^\[(NEW|CHG|DEL)\]')
    err=$(printf '%s' "$clean" | grep -i -E -m1 'failed|not available|error|could not|unable|no device|not connected|not paired|not trusted|timeout|timed out' | sed 's/^ *//;s/ *$//' | cut -c1-100)
    [[ -z "$err" ]] && err="could not pair — make sure the device is in pairing mode"
    eww update sysnotif_type="information"
    eww update "sysnotif_text_main=Failed to connect to \"$(esc "$name")\": $(esc "$err")"
    eww update "sysnotif_text_butl=Retry"
    eww update "sysnotif_text_butr=Dismiss"
    eww update "sysnotif_commandbl=$CONF/bt_connect.sh \"$(esc "$mac")\" \"$(esc "$name")\" &"
    eww update sysnotif_commandbr="eww close system_notification"
    eww open --no-daemonize system_notification
  }

  send "agent on"; sleep 1
  while IFS= read -r -t 1 -u "$bout" -n 1024 chunk; do buf+="$chunk"; done
  buf=""
  send "default-agent"
  send "pairable on"
  sleep 1
  while IFS= read -r -t 1 -u "$bout" -n 1024 chunk; do buf+="$chunk"; done
  buf=""

  send "pair $mac"
  local prc=2
  wait_for 'Pairing successful|AlreadyExists|already paired' \
           'Failed to pair|not available|AuthenticationFailed|Authentication Canceled|Connection aborted' 30
  prc=$?
  if [[ $prc -ne 0 ]]; then
    bluetoothctl info "$mac" 2>/dev/null | grep -q -E 'Paired: yes|Connected: yes' || { finish_fail; return; }
  fi

  send "trust $mac"
  sleep 1
  send "connect $mac"
  wait_for 'Connection successful|AlreadyConnected|already connected' \
           'Failed to connect|not available|Protocol not available|Host is down|Connection refused' 15

  send "quit"
  wait "$BT_PID" 2>/dev/null
  trap - TERM INT
  rm -f "$PIDF"

  local info
  info=$(bluetoothctl info "$mac" 2>/dev/null)
  if echo "$info" | grep -q -E 'Paired: yes|Connected: yes'; then
    eww close system_notification 2>/dev/null
  else
    buf+=""
    finish_fail
  fi
}

case "$1" in
  --disconnect) bluetoothctl disconnect "$2" &>/dev/null ;;
  *) connect_mode "$1" "$2" ;;
esac
