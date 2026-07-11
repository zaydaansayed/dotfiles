#!/bin/bash

command=$(eww active-windows | grep "screenprint")

if [[ $command == "screenprint: screenprint" ]]; then 
	eww close screenprint
else
	eww open screenprint
fi
