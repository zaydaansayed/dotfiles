#!/bin/bash
# wallpaper-next.sh — cycle to the next wallpaper and apply it via hyprpaper.
# Candidates: ~/Pictures/Wallpapers/* then the active theme's images dir
# (workspace thumbnails excluded). No-op with a notification if only one exists.
set -u

HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
THEME_DIR="$HOME/.config/eww/themes/$(cat "$HOME/.config/eww/themes/current_theme.txt" 2>/dev/null || echo night_sky)/images"

mapfile -t CANDS < <(
  {
    ls "$HOME/Pictures/Wallpapers/"*.png "$HOME/Pictures/Wallpapers/"*.jpg 2>/dev/null
    ls "$THEME_DIR"/wallpaper*.png "$THEME_DIR"/wallpaper*.jpg 2>/dev/null | grep -v "workspace" || true
  } | sort -u
)

if ((${#CANDS[@]} <= 1)); then
  notify-send "Wallpaper" "Only one wallpaper found — add more to ~/Pictures/Wallpapers" 2>/dev/null || true
  exit 0
fi

current=$(grep -m1 'path' "$HYPRPAPER_CONF" 2>/dev/null | awk '{print $NF}' | sed "s|\$HOME|$HOME|")
idx=-1
for i in "${!CANDS[@]}"; do
  [[ "${CANDS[$i]}" == "$current" ]] && { idx=$i; break; }
done
next="${CANDS[$(((idx + 1) % ${#CANDS[@]}))]}"

cat > "$HYPRPAPER_CONF" << EOF
wallpaper {
    monitor =
    path = $next
    fit_mode = cover
}
splash = false
EOF

killall hyprpaper 2>/dev/null || true
hyprpaper >/dev/null 2>&1 &
disown 2>/dev/null || true
notify-send "Wallpaper" "$(basename "$next")" 2>/dev/null || true
