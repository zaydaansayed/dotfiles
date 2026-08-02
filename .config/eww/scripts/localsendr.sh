#!/bin/bash

export PATH="$HOME/.local/bin:$PATH"

received() {
  local sender
  sender=$(echo "$1" | sed -n 's/.*Received request from \(.*\),device is.*/\1/p')

  if [ -z "$sender" ]; then
    sender="Someone"
  fi

  eww update sysnotif_text_main="$sender sent you a file"
  eww update sysnotif_text_butr="Ok"
  eww update sysnotif_text_butl="Cancel"
  eww update sysnotif_commandr="eww close system_notification"
  eww update sysnotif_commandl="eww close system_notification"
  eww close localsend
  eww open system_notification && killall localsend-cli
}

localsend-cli --quick-save --device-name=linux receive | grep --line-buffered "Received request from" | while read -r event; do
  received "$event"
done
