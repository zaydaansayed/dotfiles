#!/bin/bash
# websearch.sh "<query>" — open a browser web search for <query>, then close
# the launcher. Used by the spotlight "search web" row and per-app buttons.
set -u

q="$*"
[[ -z "${q// }" ]] && exit 0

url="https://www.google.com/search?q=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote_plus(sys.argv[1]))' "$q")"
command -v firefox >/dev/null 2>&1 && firefox "$url" &>/dev/null & \
  || xdg-open "$url" &>/dev/null &

command -v eww >/dev/null 2>&1 && {
  eww close launcher 2>/dev/null || true
  eww update launcher_query="" 2>/dev/null || true
  eww update files_json="[]" 2>/dev/null || true
  hyprctl dispatch 'hl.dsp.submap ("reset")' 2>/dev/null || true
}
