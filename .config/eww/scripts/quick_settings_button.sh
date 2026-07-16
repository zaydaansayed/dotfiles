#!/bin/bash

command=$(eww active-windows | grep "quick_settings")

if [[ $command == "quick_settings: quick_settings" ]]; then 
	eww close quick_settings
else
	eww open quick_settings
fi
