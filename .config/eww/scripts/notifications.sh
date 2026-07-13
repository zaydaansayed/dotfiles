#!/bin/bash
dbus-monitor "interface='org.freedesktop.Notifications',member='Notify'" | awk '
/member=Notify/ { valid=1; app=""; title=""; body=""; c=0 }
/member=(NameAcquired|NameLost)/ { valid=0 }
/string/ {
    if (valid) {
        c++
        # Clean up the dbus formatting
        gsub(/^ *string "/, ""); gsub(/" *$/, "")
        
        if (c == 1) app = $0
        if (c == 3) title = $0
        if (c == 4) {
            body = $0
            # Clean up quotes so they do not break JSON parsing
            gsub(/"/, "\\\"", app)
            gsub(/"/, "\\\"", title)
            gsub(/"/, "\\\"", body)
            
            # Print as a single line JSON and immediately flush
            printf "{\"app\": \"%s\", \"title\": \"%s\", \"body\": \"%s\"}\n", app, title, body
            fflush()
        }
    }
}'
