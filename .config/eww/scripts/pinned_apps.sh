#!/bin/bash

get_target_apps() {
  # 1. Grab the unique window address of the focused client
  focused_address=$(hyprctl activewindow -j | jq -r '.address // "none"')

  # 2. Extract client state data (removed pid from initial object projection)
  hyprctl clients -j | jq -c '.[] | {address: .address, title: .title, lookup: (.initialClass // .class)}' | while read -r row; do
    [ -z "$row" ] && continue

    address=$(echo "$row" | jq -r '.address')
    title=$(echo "$row" | jq -r '.title')
    lookup=$(echo "$row" | jq -r '.lookup' | tr '[:upper:]' '[:lower:]')

    case "$lookup" in
      *firefox*) app_name="firefox" ;;
      *spotify*) app_name="Spotify" ;;
      *) continue ;;
    esac

    # 3. Use strict address matching to fix the duplicate focus highlighting bug
    is_focused="false"
    [ "$address" = "$focused_address" ] && is_focused="true"

    # 4. Construct final output payload (removed all pid arguments)
    jq -nc \
      --arg name "$app_name" \
      --argjson focused "$is_focused" \
      --arg address "$address" \
      --arg title "$title" \
      '{"name": $name, "focused": $focused, "address": $address, "title": $title}'
  done | jq -c -s .
}

get_target_apps

socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | \
  grep --line-buffered -E "openwindow|closewindow|activewindow" | \
  while read -r event; do
    get_target_apps
done

