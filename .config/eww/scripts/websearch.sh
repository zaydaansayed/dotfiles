#!/bin/bash

q="$*"

zen-browser https://www.google.com/search?q="$q" &
eww close launcher 2>/dev/null || true
eww update launcher_query="" 2>/dev/null || true
eww update files_json="[]" 2>/dev/null || true
hyprctl dispatch 'hl.dsp.submap ("reset")'
