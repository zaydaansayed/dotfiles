#!/bin/bash
# Kill background monitors (rfkill/nmcli/gdbus) when eww kills this script,
# otherwise `eww reload` leaves orphans that pile up and desync the daemon.
cleanup() { jobs -p | xargs -r kill 2>/dev/null; pkill -P $$ 2>/dev/null; exit 0; }
trap cleanup EXIT TERM INT

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/eww-airplane-mode.state"
rm -f "$STATE_FILE"

get_airplane() {
    local wifi_off=false bt_off=false icon last

    if rfkill list wifi 2>/dev/null | grep -qi "blocked: yes"; then
        wifi_off=true
    elif [[ "$(nmcli radio wifi 2>/dev/null)" != "enabled" ]]; then
        wifi_off=true
    elif [[ "$(nmcli networking 2>/dev/null)" != "enabled" ]]; then
        wifi_off=true
    fi

    if rfkill list bluetooth 2>/dev/null | grep -qi "blocked: yes"; then
        bt_off=true
    elif ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        bt_off=true
    fi

    if [[ "$wifi_off" == true && "$bt_off" == true ]]; then
        icon="󰀝"
    else
        icon="󰀞"
    fi
    last="$(cat "$STATE_FILE" 2>/dev/null)"
    if [[ "$icon" != "$last" ]]; then
        echo "$icon"
        printf "%s" "$icon" > "$STATE_FILE"
    fi
}

get_airplane

( stdbuf -oL rfkill event 2>/dev/null | while read -r _; do
    sleep 0.3
    get_airplane
done ) &

( nmcli monitor 2>/dev/null | while read -r _; do
    sleep 0.3
    get_airplane
done ) &

( gdbus monitor --system --dest org.bluez 2>/dev/null \
    | grep --line-buffered -E 'Powered|Connected|InterfacesAdded|InterfacesRemoved' \
    | while read -r _; do
        sleep 0.5
        get_airplane
    done ) &

while true; do
    sleep 10
    get_airplane
done
