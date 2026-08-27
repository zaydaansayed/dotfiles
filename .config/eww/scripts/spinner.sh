#!/bin/bash
frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

modulus=${#frames[@]}
current_time=$(date +%s%N)
idx=$(( (current_time / 100000000) % modulus ))

echo "${frames[$idx]}"
