#!/bin/bash
# launcher-query.sh "<query>" — called on every launcher keystroke.
# Updates launcher_query (app filter) AND files_json (file results) together
# so the spotlight window shows apps + files + web search in one view.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
q="${1:-}"

eww update "launcher_query=$q" 2>/dev/null || true
files=$("$SCRIPT_DIR/launcher.sh" files "$q" 2>/dev/null || echo '[]')
eww update "files_json=$files" 2>/dev/null || true
