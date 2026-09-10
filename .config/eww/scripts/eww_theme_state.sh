#!/bin/bash
# eww_theme_state.sh — defpoll for settings > UI.
# Reads the CURRENT theme's colors.scss so the opacity slider (and accent
# swatches) reflect reality instead of hardcoded defaults.
# Emits: {"bg_alpha":0-100,"accent":"#RRGGBB"}

theme=$(cat ~/.config/eww/themes/current_theme.txt 2>/dev/null | tr -d '[:space:]')
colors="$HOME/dotfiles/.config/eww/themes/${theme:-night_sky}/eww/scss/colors.scss"

bg=$(grep -oP '\$bg:\s*\K[^;]+' "$colors" 2>/dev/null | head -n1 | xargs)
accent=$(grep -oP '\$on:\s*\K#[0-9a-fA-F]{3,6}' "$colors" 2>/dev/null | head -n1)

alpha=1
if [[ "$bg" =~ ,[[:space:]]*([0-9.]+)[[:space:]]*\)[[:space:]]*$ ]]; then
  alpha="${BASH_REMATCH[1]}"
fi
pct=$(awk -v a="$alpha" 'BEGIN { v=int(a*100+0.5); if (v<0) v=0; if (v>100) v=100; print v }')

# normalize accent to 6-digit uppercase
accent="${accent:-#E99AFF}"
h="${accent#\#}"
if [[ ${#h} -eq 3 ]]; then
  h="${h:0:1}${h:0:1}${h:1:1}${h:1:1}${h:2:1}${h:2:1}"
fi
accent="#$(printf '%s' "$h" | tr 'a-z' 'A-Z')"

jq -nc --argjson bg_alpha "$pct" --arg accent "$accent" \
  '{bg_alpha: $bg_alpha, accent: $accent}'
