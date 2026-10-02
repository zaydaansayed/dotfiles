#!/bin/bash

powerprofile=$(tlp-stat -s | grep -oP '(?<=TLP profile    = )\w+')

if [[ "$powerprofile" == "balanced" ]]; then
  echo ""
elif [[ "$powerprofile" == "performance" ]]; then
  echo "󱐋"
elif [[ "$powerprofile" == "power" || "$powerprofile" == "power-saver" ]]; then
  echo ""
fi
