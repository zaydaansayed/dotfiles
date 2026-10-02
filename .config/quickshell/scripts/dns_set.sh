#!/bin/bash
# dns_set.sh — DNS actions for settings (native, no applets).
# usage:
#   dns_set.sh auto
#   dns_set.sh preset <cloudflare|google|quad9|adguard>
#   dns_set.sh custom "1.1.1.1 8.8.8.8"
# Changing DNS reconnects briefly.

active_uuid() {
  nmcli -t -f UUID,TYPE,DEVICE con show --active 2>/dev/null \
    | grep -E ':(802-11-wireless|802-3-ethernet):' | head -n1 | cut -d: -f1
}

uuid=$(active_uuid)
[[ -z "$uuid" ]] && exit 0

case "$1" in
  auto)
    nmcli con mod uuid "$uuid" ipv4.dns "" ipv4.ignore-auto-dns no 2>/dev/null
    ;;
  preset)
    case "$2" in
      cloudflare) s="1.1.1.1 1.0.0.1" ;;
      google) s="8.8.8.8 8.8.4.4" ;;
      quad9) s="9.9.9.9 149.112.112.112" ;;
      adguard) s="94.140.14.14 94.140.15.15" ;;
      *) exit 1 ;;
    esac
    nmcli con mod uuid "$uuid" ipv4.dns "$s" ipv4.ignore-auto-dns yes 2>/dev/null
    ;;
  custom)
    [[ -z "$2" ]] && exit 0
    nmcli con mod uuid "$uuid" ipv4.dns "$2" ipv4.ignore-auto-dns yes 2>/dev/null
    ;;
  *) exit 1 ;;
esac

# re-apply (brief reconnect)
nmcli con up uuid "$uuid" &>/dev/null &
