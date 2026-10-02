#!/bin/bash

get_history_json() {
        if ! OUTPUT=$(makoctl history 2>/dev/null); then
        echo "[]"
        return
    fi

    echo "$OUTPUT" | awk '
    BEGIN {
        printf "["
        first = 1
    }
    /^Notification / {
        if (!first) {
            printf "},"
        }
        first = 0
        match($0, /: /)
        title = substr($0, RSTART + 2)
        gsub(/"/, "\\\"", title)
        printf "{\"title\":\"%s\"", title
        next
    }
    /^[ \t]*App name:/ {
        match($0, /: /)
        app = substr($0, RSTART + 2)
        gsub(/"/, "\\\"", app)
        printf ",\"app\":\"%s\"", app
        next
    }
    /^[ \t]*Urgency:/ {
        match($0, /: /)
        urgency = substr($0, RSTART + 2)
        printf ",\"urgency\":\"%s\"", urgency
        next
    }
    END {
        if (!first) {
            printf "}"
        }
        print "]"
    }'
}

get_history_json

stdbuf -oL dbus-monitor "interface='org.freedesktop.Notifications'" \
                       "interface='org.freedesktop.DBus',member='NameOwnerChanged'" 2>/dev/null | \
grep --line-buffered -E "Notify|NotificationClosed|NameOwnerChanged" | \
while read -r _; do
    sleep 0.05
    get_history_json
done
