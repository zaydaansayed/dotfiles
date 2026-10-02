#!/bin/bash
# profile-picker-query.sh "<query>" — called on every picker keystroke.
# Mirrors scripts/launcher-query.sh: updates the query var AND the
# image results JSON together so the window filters live.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
q="${1:-}"

eww update "profile_picker_query=$q" 2>/dev/null || true
images=$("$SCRIPT_DIR/profile-picker.sh" images "$q" 2>/dev/null || echo '[]')
eww update "profile_images_json=$images" 2>/dev/null || true
