#!/bin/bash
PIDF=/tmp/eww_bt_scan.pid
EXPF=/tmp/eww_bt_scan.exp

stop_scan() {
  if [[ -f "$PIDF" ]]; then
    kill "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null
    rm -f "$PIDF" "$EXPF"
  fi
  bluetoothctl scan off &>/dev/null
  sleep 1
  if bluetoothctl show 2>/dev/null | grep -q 'Discovering: yes'; then
    bluetoothctl power off &>/dev/null
    sleep 2
    bluetoothctl power on &>/dev/null
  fi
}

case "$1" in
  stop) stop_scan ;;
  *)
    if [[ -f "$PIDF" ]] && kill -0 "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null; then
      stop_scan
    else
      stop_scan
      bluetoothctl power on &>/dev/null
      bluetoothctl < <(echo "scan on"; sleep 25) &>/dev/null &
      echo $! > "$PIDF"
      echo $(( $(date +%s) + 25 )) > "$EXPF"
    fi
    ;;
esac
