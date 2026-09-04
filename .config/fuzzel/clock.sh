#!/usr/bin/env bash

choice=$(echo -e "󰥔 Clock\n󱎫 Timer\n Stopwatch\n󰆙 Countdown" | fuzzel --lines 4 --dmenu --prompt="Clock: ")

case "$choice" in
    "󰥔 Clock")
        kitty -e tclock clock	
	;;
    "󱎫 Timer")
        duration=$(fuzzel --dmenu --lines 0 -w 40 --prompt="Timer duration (e.g. 10m, 30s): ")
        [ -n "$duration" ] && kitty -e tclock timer -d "$duration" -e "ffplay -loop 0 -nodisp /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
	;;
    " Stopwatch")
        kitty -e tclock stopwatch
        ;;
    "󰆙 Countdown")        
        target_time=$(fuzzel --lines 0 -w 40 --dmenu --prompt="Target time (e.g. 17:00): ")
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
