#!/bin/bash

export PATH="$HOME/.local/bin:$PATH"

received() {
  local sender
  sender=$(echo "$1" | sed -n 's/.*Incoming transfer from \(.*\) ([0-9.]*):.*/\1/p')

  if [ -z "$sender" ]; then
    sender="Someone"
  fi
  
  eww update sysnotif_type="information"
  eww update sysnotif_text_main="$sender sent you a file"
  eww update sysnotif_text_butr="Ok"
  eww update sysnotif_text_butl="Cancel"
  eww update sysnotif_commandbr="eww close system_notification"
  eww update sysnotif_commandbl="eww close system_notification"
  eww open system_notification 
}

localsend-cli receive -y | grep --line-buffered "Incoming transfer from" | while read -r event; do
  received "$event"
done
