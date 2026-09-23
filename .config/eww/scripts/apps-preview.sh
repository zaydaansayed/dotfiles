#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ID="${1:-}"
[[ -z "$ID" ]] && { echo "usage: $(basename "$0") <app-id>" >&2; exit 1; }
command -v grim >/dev/null 2>&1 || { echo "error: grim not found" >&2; exit 1; }

PREVIEW_DIR="${XDG_RUNTIME_DIR:-/tmp}/eww-previews"
MISSING_IMG="$SCRIPT_DIR/../images/preview-missing.png"
mkdir -p "$PREVIEW_DIR"

ID="$ID" PREVIEW_DIR="$PREVIEW_DIR" MISSING_IMG="$MISSING_IMG"
export ID PREVIEW_DIR MISSING_IMG
"$SCRIPT_DIR/apps.sh" view 2>/dev/null | python3 -c '
import json, os, subprocess, sys

data = json.load(sys.stdin)
key = os.environ["ID"]
outdir = os.environ["PREVIEW_DIR"]
missing = os.environ.get("MISSING_IMG", "")

grp = None
for p in data.get("pinned", []):
    if p["id"] == key and p["active"]:
        grp = {"icon": p["icon"], "windows": p["windows"]}
        break
if grp is None:
    for a in data.get("active", []):
        if a.get("desktop") == key or a["icon"] == key:
            grp = {"icon": a["icon"], "windows": a["windows"]}
            break
if not grp:
    print("[]")
    sys.exit(0)

clients = {c["address"]: c for c in
           json.loads(subprocess.check_output(["hyprctl", "-j", "clients"]).decode())}
try:
    active_ws = json.loads(subprocess.check_output(["hyprctl", "-j", "activeworkspace"]).decode()).get("id")
except Exception:
    active_ws = None

import shutil
have_grim = shutil.which("grim") is not None
result = []
for w in grp["windows"]:
    addr = w["address"]
    cached = os.path.join(outdir, f"win-{addr}.png")
    shot = ""
    c = clients.get(addr)
    if have_grim and c and c.get("mapped", False) and not c.get("hidden", False):
        ws = (c.get("workspace") or {}).get("id")
        at, size = c.get("at", [0, 0]), c.get("size", [0, 0])
        if (ws is None or ws == active_ws) and size[0] >= 60 and size[1] >= 60:
            r = subprocess.run(
                ["grim", "-g", f"{at[0]},{at[1]} {size[0]}x{size[1]}", cached],
                capture_output=True, timeout=15)
            if r.returncode == 0 and os.path.exists(cached):
                shot = cached
    if not shot and os.path.exists(cached):
        # off-workspace window: reuse last screenshot (may be stale)
        shot = cached
    result.append({"address": addr, "title": w["title"],
                   "focused": w["focused"], "icon": grp["icon"],
                   "shot": bool(shot),
                   "preview": shot if shot else missing})
print(json.dumps(result))
' | {
  read -r json || json=""
  [[ "$json" == "["* ]] || json="[]"
  eww update "selected_windows=$json"
}
