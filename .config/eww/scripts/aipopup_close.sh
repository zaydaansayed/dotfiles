#!/bin/bash

lines=$(eww active-windows | grep -E "loading-popup|copy-popup" | wc -l)
open_window=$(eww active-windows | grep -E "loading-popup|copy-popup" | awk -F': ' '{print $2}')

if [[ $lines -eq 0 ]]; then
	:
elif [[ $lines -eq 1 ]]; then
	eww close $open_window
else 
	eww close copy-popup
	eww close loading-popup
fi
