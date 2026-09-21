#!/bin/bash

brightness() {
  brightness=$(brightnessctl i | grep -oP '\(\K[0-9]+(?=%\))')
  [[ -z "$brightness" ]] && brightness=50

  filled=$(( brightness * 10 / 100 ))
  empty=$(( 10 - filled ))
  bar=""
  for ((i=0;i<filled;i++)); do bar+="█"; done
  for ((i=0;i<empty;i++)); do bar+="░"; done

  echo $bar
}

brightness

udevadm monitor --subsystem=backlight --property | grep --line-buffered "POWER_SUPPLY_CAPACITY\|CURRENT" | while read -r event; do
    brightness
done

