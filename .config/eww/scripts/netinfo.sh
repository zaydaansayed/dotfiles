#!/bin/bash
cleanup() { jobs -p | xargs -r kill 2>/dev/null; pkill -P $$ 2>/dev/null; exit 0; }
trap cleanup EXIT TERM INT

LAST_OUTPUT=""

get_internet() {
    local net_state wifi_state netname icon strength new_output ethernet
    local wifi_on=false net_on=false

    net_state=$(nmcli networking)
    wifi_state=$(nmcli radio wifi)
    [[ "$net_state" == "enabled" ]] && net_on=true
    [[ "$wifi_state" == "enabled" ]] && wifi_on=true

    netname=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2-)

    ethernet=false
    if ip route 2>/dev/null | grep -qE "dev (eth|enp)"; then
        ethernet=true
    fi

    if [[ "$net_state" != "enabled" || "$wifi_state" != "enabled" ]]; then
        icon="󰤭"
    elif [[ "$ethernet" == true ]]; then
        icon=""
    else
        strength=$(nmcli -t -f SIGNAL,ACTIVE dev wifi 2>/dev/null | awk -F: '$2=="yes" {print $1}')

        if [[ -z "$strength" || "$strength" -eq 0 ]]; then
            icon="󰤯"
        elif [[ $strength -le 25 ]]; then icon="󰤟"
        elif [[ $strength -le 50 ]]; then icon="󰤢"
        elif [[ $strength -le 75 ]]; then icon="󰤥"
        else icon="󰤨"
        fi
    fi
    [[ "$strength" =~ ^[0-9]+$ ]] || strength=0

    local networks="[]"
    if [[ "$wifi_on" == true ]]; then
        networks=$(nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE dev wifi list --rescan no 2>/dev/null \
          | grep -v '^:' \
          | awk -F: '!seen[$1]++' \
          | head -n 20 \
          | jq -R -s '
              split("\n") | map(select(length > 0)) |
              map(split(":") |
                {"ssid": .[0],
                 "signal": (.[1] | tonumber? // 0),
                 "security": (.[2] // ""),
                 "active": (.[3] == "*")})')
        [[ -z "$networks" ]] && networks="[]"
    fi

    local active
    active=$(echo "$networks" | jq -r '[.[] | select(.active) | .ssid] | first // ""')
    [[ -z "$active" ]] && active="$netname"

    new_output=$(jq -nc --arg icon "$icon" --arg netname "$netname" \
      --argjson wifi_on "$wifi_on" --argjson net_on "$net_on" \
      --argjson ethernet "$ethernet" --argjson strength "$strength" \
      --arg active "$active" --argjson networks "$networks" \
      '{icon: $icon, netname: $netname, wifi_on: $wifi_on, net_on: $net_on,
        ethernet: $ethernet, strength: $strength, active: $active, networks: $networks}')

    if [[ "$new_output" != "$LAST_OUTPUT" ]]; then
        echo "$new_output"
        LAST_OUTPUT="$new_output"
    fi
}

get_internet

(
    while true; do
        sleep 30
        get_internet
    done
) &

nmcli monitor 2>/dev/null | while read -r _; do
    sleep 0.2
    get_internet
done
