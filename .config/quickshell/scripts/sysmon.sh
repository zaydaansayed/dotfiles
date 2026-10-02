#!/bin/bash
# sysmon.sh — {"cpu":pct,"mem":pct,"disk":pct} for the desktop sysmon widget.
set -u

while true; do
  cpu=$(top -bn1 2>/dev/null | awk '/Cpu\(s\)/{printf "%d", 100-$8}')
  mem=$(free 2>/dev/null | awk '/^Mem/{printf "%d", $3/$2*100}')
  disk=$(df / 2>/dev/null | awk 'NR==2{gsub(/%/,""); print $5}')
  echo "{\"cpu\":${cpu:-0},\"mem\":${mem:-0},\"disk\":${disk:-0}}"
  sleep 2
done
