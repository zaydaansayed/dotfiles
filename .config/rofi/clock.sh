#!/usr/bin/env bash

choice=$(echo -e "󰥔 Clock\n󱎫 Timer\n Stopwatch\n󰆙 Countdown" | rofi -dmenu -p "Clock" -l 4 )

case "$choice" in
    "󰥔 Clock")
        kitty -e tclock clock	
	;;
    "󱎫 Timer")
        duration=$(rofi -dmenu -p "Timer duration (e.g. 10m, 30s)" -l 0)
        [ -n "$duration" ] && kitty -e tclock timer -d "$duration" -e "ffplay -loop 0 -nodisp /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
	;;
    " Stopwatch")
        kitty -e tclock stopwatch
        ;;
    "󰆙 Countdown")        
        target_time=$(rofi -dmenu -p "Target time (e.g. 17:00)" -l 0)
        if [ -n "$target_time" ]; then
          target_sec=$(date -d "today $target_time" +%s 2>/dev/null)
          now_sec=$(date +%s)

          if [ "$target_sec" -lt "$now_sec" ]; then
              target_sec=$(date -d "tomorrow $target_time" +%s)
          fi
 
          diff_sec=$(( target_sec - now_sec ))

          kitty -e tclock timer -d "${diff_sec}s" -e "ffplay -loop 0 -nodisp /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
        fi
        ;;
    *)
        exit 0
        ;;
esac
