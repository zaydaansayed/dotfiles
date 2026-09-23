#!/bin/bash
# obs_state.sh — {"running":bool,"recording":bool} for the eww bar OBS indicator.
# Recording is probed via obs-cmd (needs OBS running with obs-websocket enabled);
# falls back to false quickly when OBS is closed.
set -u

while true; do
  if pgrep -x obs >/dev/null 2>&1; then
    out=$(timeout 3 obs-cmd recording status 2>/dev/null || true)
    if echo "$out" | grep -qiE 'recording[^a-z]*true|is recording|"recording"[[:space:]]*:[[:space:]]*true'; then
      echo '{"running":true,"recording":true}'
    else
      echo '{"running":true,"recording":false}'
    fi
  else
    echo '{"running":false,"recording":false}'
  fi
  sleep 2
done
