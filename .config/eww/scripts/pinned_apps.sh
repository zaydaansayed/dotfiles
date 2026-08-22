#!/bin/bash

get_target_apps() {
  focused_address=$(hyprctl activewindow -j | jq -r '.address // "none"')
  
  hyprctl clients -j | jq -c --arg focused "$focused_address" '
    [ .[] | 
      ((.initialClass // .class) | ascii_downcase) as $lookup |
      if ($lookup | contains("firefox")) then "firefox"
      elif ($lookup | contains("spotify")) then "Spotify"
      else empty
      end as $app_name |
      {
        name: $app_name,
        focused: (.address == $focused),
        address: .address,
        title: .title
      }
    ] as $apps |
    {
      apps: $apps,
      firefox_open: ($apps | any(.name == "firefox")),
      firefox_focused: ($apps | any(.name == "firefox" and .focused)),
      spotify_open: ($apps | any(.name == "Spotify")),
      spotify_focused: ($apps | any(.name == "Spotify" and .focused))
    }
  '
}

get_target_apps

socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | \
  grep --line-buffered -E "openwindow|closewindow|activewindow" | \
  while read -r _; do
    get_target_apps
  done
