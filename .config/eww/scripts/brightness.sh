#!/bin/bash

print_brightness() {
    brightnessctl i | grep -oP '\(\K[0-9]+(?=%\))'
}

print_brightness

udevadm monitor --subsystem=backlight --property | grep --line-buffered "POWER_SUPPLY_CAPACITY\|CURRENT" | while read -r event; do
    print_brightness
done
