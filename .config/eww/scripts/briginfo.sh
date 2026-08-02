#!/bin/bash

brightness() {
  brightness=$(brightnessctl i | grep -oP '\(\K[0-9]+(?=%\))')
  

  if [[ $brightness -le 10 ]]; then
      icon="󰃞 "
  elif [[ $brightness -le 35 ]]; then
      icon="󰃝 "
  elif [[ $brightness -le 50 ]]; then
      icon="󰃟 "
  else
      icon="󰃠 "
  fi

  echo "{\"icon\": \"$icon\", \"brightness\": \"$brightness\"}"
}

brightness

udevadm monitor --subsystem=backlight --property | grep --line-buffered "POWER_SUPPLY_CAPACITY\|CURRENT" | while read -r event; do
    brightness
done

