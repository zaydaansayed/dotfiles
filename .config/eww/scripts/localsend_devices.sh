#!/usr/bin/env bash

export PATH="$PATH:/usr/local/bin:$HOME/.local/bin:$HOME/.cargo/bin"

# Get local IP addresses and hostname to filter out self-discovery
MY_IPS=$(hostname -I 2>/dev/null || ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+')
MY_HOST=$(hostname 2>/dev/null)

parsed_output=$(localsend-cli discover 2>/dev/null | awk -v my_ips="$MY_IPS" -v my_host="$MY_HOST" '
  BEGIN {
    split(my_ips, arr, " ")
    for (i in arr) {
      if (arr[i] != "") local_ips[arr[i]] = 1
    }
  }
  /IP:/ {
    device = prev;
    sub(/^[ \t]+/, "", device);
    ip_full = $2;
    
    split(ip_full, ip_parts, ":")
    ip_only = ip_parts[1]
  }
  /Type:|Model:/ {
    info = $0;

    # Skip if IP or device name matches local machine
    if ((ip_only in local_ips) || (tolower(device) == tolower(my_host))) {
      device = ""
      next
    }

    # Icon selection
    if (tolower(device) ~ /iphone|ipad/ || tolower(info) ~ /ios/) {
      icon = "";
    } else if (tolower(device) ~ /android|samsung|pixel/ || tolower(info) ~ /android/) {
      icon = "";
    } else if (tolower(device) ~ /mac|macbook|apple/ || tolower(info) ~ /mac/) {
      icon = "󰌢";
    } else if (tolower(device) ~ /linux|arch/ || tolower(info) ~ /linux/) {
      icon = "";
    } else {
      icon = "";
    }

    if (device != "") {
      print device "|||" icon;
    }
  }
  { prev = $0 }
')

if [ -z "$parsed_output" ]; then
  echo "[]"
else
  echo "$parsed_output" | jq -R -s -c '
    split("\n") 
    | map(select(length > 0)) 
    | map(split("|||") | {"device": .[0], "icon": .[1]})
  '
fi
