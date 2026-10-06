#!/bin/bash
brightnessctl i | grep -oP '\(\K[0-9]+(?=%\))'

udevadm monitor --subsystem=backlight --property | grep --line-buffered "POWER_SUPPLY_CAPACITY\|CURRENT" | while read -r event; do
  brightnessctl i | grep -oP '\(\K[0-9]+(?=%\))'
done
