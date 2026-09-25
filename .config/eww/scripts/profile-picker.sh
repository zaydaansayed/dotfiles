#!/bin/bash
# profile-picker.sh — backend for the launcher-style profile picture picker.
# Mirrors scripts/launcher.sh structure (list via fd/find + python JSON).
#
# Usage:
#   profile-picker.sh images [query]  — JSON array [{name, path}] of images
#   profile-picker.sh apply <path>    — copy <path> to profile_picture.png
#   profile-picker.sh open            — reset vars, preload, open picker window
set -u

TARGET_FILE="$HOME/.config/eww/images/profile_picture.png"
MAX_RESULTS=30

# do_images <query> — up to $MAX_RESULTS png/jpg/jpeg/webp under $HOME.
# Empty/short query -> most recent images. Longer query -> substring match
# on basename or full path (case-insensitive). Noisy dirs pruned.
do_images() {
    local q="${1:-}"
    if command -v fd >/dev/null 2>&1; then
        fd -H -t f -e png -e jpg -e jpeg -e webp \
            -E .cache -E .cargo -E .rustup -E .mozilla -E .local/share/Trash \
            -E node_modules -E .git -E __pycache__ -E .local/share/flatpak \
            . "$HOME" 2>/dev/null | QUERY="$q" MAX_RESULTS="$MAX_RESULTS" python3 -c '
import json, os, sys

q = os.environ.get("QUERY", "").strip().lower()
try:
    limit = int(os.environ.get("MAX_RESULTS", "30"))
except ValueError:
    limit = 30

paths = [line.rstrip("\n") for line in sys.stdin if line.strip()]

if len(q) >= 2:
    kept = [p for p in paths
            if q in os.path.basename(p).lower() or q in p.lower()]
    kept.sort(key=lambda p: os.path.basename(p).lower())
else:
    # Most recent first so an empty query still shows something useful.
    def mtime(p):
        try:
            return os.path.getmtime(p)
        except OSError:
            return 0
    kept = sorted(paths, key=mtime, reverse=True)

out = [{"name": os.path.basename(p.rstrip("/")), "path": p}
       for p in kept[:limit]]
print(json.dumps(out))'
    else
        find "$HOME" \( -path "$HOME/.cache*" -o -path "$HOME/.mozilla*" \
            -o -name .git -o -name node_modules -o -name __pycache__ \) -prune \
            -o -type f \( -iname "*.png" -o -iname "*.jpg" \
            -o -iname "*.jpeg" -o -iname "*.webp" \) -print 2>/dev/null \
            | QUERY="$q" MAX_RESULTS="$MAX_RESULTS" python3 -c '
import json, os, sys

q = os.environ.get("QUERY", "").strip().lower()
try:
    limit = int(os.environ.get("MAX_RESULTS", "30"))
except ValueError:
    limit = 30

paths = [line.rstrip("\n") for line in sys.stdin if line.strip()]

if len(q) >= 2:
    kept = [p for p in paths
            if q in os.path.basename(p).lower() or q in p.lower()]
    kept.sort(key=lambda p: os.path.basename(p).lower())
else:
    def mtime(p):
        try:
            return os.path.getmtime(p)
        except OSError:
            return 0
    kept = sorted(paths, key=mtime, reverse=True)

out = [{"name": os.path.basename(p.rstrip("/")), "path": p}
       for p in kept[:limit]]
print(json.dumps(out))'
    fi
}

do_apply() {
    local src="${1:-}"
    if [[ -z "$src" ]]; then
        echo '{"error":"no image path"}' >&2
        return 1
    fi
    if [[ ! -f "$src" ]]; then
        notify_error "File not found: $src"
        return 1
    fi
    case "${src,,}" in
        *.png|*.jpg|*.jpeg|*.webp) ;;
        *)
            notify_error "Not an image (png/jpg/jpeg/webp): $src"
            return 1
            ;;
    esac

    mkdir -p "$(dirname "$TARGET_FILE")"
    if cp "$src" "$TARGET_FILE"; then
        command -v eww >/dev/null 2>&1 && {
            eww close profile_picker 2>/dev/null || true
            eww update profile_picker_query="" 2>/dev/null || true
            eww update profile_images_json="[]" 2>/dev/null || true
            eww update selected_profile_path="" 2>/dev/null || true
            eww update selected_profile_name="" 2>/dev/null || true
            # Reload so CSS background-image picks up the new png,
            # then stay on the pfp setup step.
            eww reload 2>/dev/null || true
            sleep 0.5
            eww update setup_step=3 2>/dev/null || true
        }
        command -v notify-send >/dev/null 2>&1 && \
            notify-send "Profile picture updated" 2>/dev/null || true
    else
        notify_error "Failed to copy the file. Check your folder permissions."
        return 1
    fi
}

notify_error() {
    local msg="${1:-Unknown error}"
    command -v notify-send >/dev/null 2>&1 && \
        notify-send -u critical "Profile picture" "$msg" 2>/dev/null || true
    # Surface inside eww too when the daemon is running.
    command -v eww >/dev/null 2>&1 && {
        eww update sysnotif_type="error" 2>/dev/null || true
        eww update "sysnotif_text_main=$msg" 2>/dev/null || true
    }
    echo "$msg" >&2
}

do_open() {
    command -v eww >/dev/null 2>&1 || { echo "eww not running" >&2; return 1; }
    eww update profile_picker_query="" 2>/dev/null || true
    eww update selected_profile_path="" 2>/dev/null || true
    eww update selected_profile_name="" 2>/dev/null || true
    local initial
    initial="$(do_images "")"
    # Escape for `eww update var=value` (value must not break parsing).
    eww update "profile_images_json=$initial" 2>/dev/null || true
    eww open profile_picker 2>/dev/null || true
}

case "${1:-images}" in
    images|list|"") shift || true; do_images "${*:-}" ;;
    apply) shift || true; do_apply "${1:-}" ;;
    open) do_open ;;
    *) echo "usage: profile-picker.sh [images [query]|apply <path>|open]" >&2; exit 1 ;;
esac
