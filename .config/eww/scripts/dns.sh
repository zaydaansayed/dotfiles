#!/bin/bash
# dns.sh — deflisten for settings > Connections > DNS card.
# Emits: {"con":"","servers":[],"auto":true,"preset":"auto"}
# preset names the matching known DNS set so buttons highlight reliably.
cleanup() { jobs -p | xargs -r kill 2>/dev/null; pkill -P $$ 2>/dev/null; exit 0; }
trap cleanup EXIT TERM INT

LAST_OUTPUT=""

preset_of() {
  case "$1" in
    1.1.1.1) echo cloudflare ;;
    8.8.8.8) echo google ;;
    9.9.9.9) echo quad9 ;;
    94.140.14.14) echo adguard ;;
    *) echo custom ;;
  esac
}

emit_dns() {
  local active uuid iface con servers auto preset first

  # active non-loopback connection: UUID,TYPE,DEVICE have no colons (NAME can)
  active=$(nmcli -t -f UUID,TYPE,DEVICE con show --active 2>/dev/null \
    | grep -E ':(802-11-wireless|802-3-ethernet):' | head -n1)
  uuid=$(echo "$active" | cut -d: -f1)
  iface=$(echo "$active" | cut -d: -f3)
  con=$(nmcli -t -f connection.id con show uuid "$uuid" 2>/dev/null | cut -d: -f2- | sed 's/\\:/:/g')

  servers="[]"; auto=true
  if [[ -n "$iface" ]]; then
    servers=$(nmcli -t -f IP4.DNS dev show "$iface" 2>/dev/null \
      | cut -d: -f2- | grep -v '^$' | jq -R -s 'split("\n") | map(select(length > 0))')
    [[ -z "$servers" ]] && servers="[]"
  fi
  if [[ -n "$uuid" ]] && [[ "$(nmcli -t -f ipv4.ignore-auto-dns con show uuid "$uuid" 2>/dev/null | cut -d: -f2-)" == "yes" ]]; then
    auto=false
  fi

  if [[ "$auto" == true ]]; then
    preset="auto"
  else
    first=$(echo "$servers" | jq -r '.[0] // ""')
    preset=$(preset_of "$first")
  fi

  local new_output
  new_output=$(jq -nc --arg con "${con:-}" --argjson servers "$servers" \
    --argjson auto "$auto" --arg preset "$preset" \
    '{con: $con, servers: $servers, auto: $auto, preset: $preset}')

  if [[ "$new_output" != "$LAST_OUTPUT" ]]; then
    echo "$new_output"
    LAST_OUTPUT="$new_output"
  fi
}

emit_dns

# single event stream: NM activity refreshes instantly, 10s tick as fallback
{
  nmcli monitor 2>/dev/null &
  while true; do sleep 10; echo TICK; done &
  wait
} | while read -r _; do
  sleep 0.5
  emit_dns
done
