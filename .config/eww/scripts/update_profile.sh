#!/bin/bash
# update_profile.sh — open the launcher-style profile picture picker.
# (Previously used zenity --file-selection; now uses the custom
# eww profile_picker window, which looks and behaves like the launcher.)
#
# The picker itself handles preview + apply via profile-picker.sh.
# This script just resets state, preloads results, and opens the window.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v eww >/dev/null 2>&1; then
    echo "eww is not running, cannot open profile picker." >&2
    exit 1
fi

# If the picker is already open, just focus it instead of stacking updates.
if eww active-windows 2>/dev/null | grep -q ": profile_picker$"; then
    exit 0
fi

eww update profile_picker_query="" 2>/dev/null || true
eww update selected_profile_path="" 2>/dev/null || true
eww update selected_profile_name="" 2>/dev/null || true

initial="$("$SCRIPT_DIR/profile-picker.sh" images "" 2>/dev/null || echo '[]')"
eww update "profile_images_json=$initial" 2>/dev/null || true

eww open profile_picker 2>/dev/null || {
    echo "Failed to open profile_picker window. Is eww daemon running?" >&2
    exit 1
}
