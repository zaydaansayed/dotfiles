#!/bin/bash

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/eww-launcher"
HISTORY_FILE="$CACHE_DIR/history.json"
OVERLAY_DIR="$HOME/.local/share/icons/hicolor/48x48/apps"
mkdir -p "$CACHE_DIR" "$OVERLAY_DIR"
[[ -f "$HISTORY_FILE" ]] || echo '{}' > "$HISTORY_FILE"

ICON_THEME=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
[[ -z "$ICON_THEME" ]] && ICON_THEME="pixora"

export OVERLAY_DIR ICON_THEME HISTORY_FILE

APP_DIRS=(
  "$HOME/.local/share/applications"
  "$HOME/.local/share/flatpak/exports/share"
  "/var/lib/flatpak/exports/share/applications"
  "/usr/local/share/applications"
  "/usr/share/applications"
)
export APP_DIRS_STR
APP_DIRS_STR=$(printf '%s\n' "${APP_DIRS[@]}")

do_list() {
  APP_DIRS_STR="$APP_DIRS_STR" HISTORY_FILE="$HISTORY_FILE" \
  OVERLAY_DIR="$OVERLAY_DIR" ICON_THEME="$ICON_THEME" python3 - << 'EOF'
import configparser, json, os, re, subprocess, time

overlay = os.environ["OVERLAY_DIR"]
theme_name = os.environ.get("ICON_THEME", "pixora") or "pixora"
hist_path = os.environ["HISTORY_FILE"]
dirs = [d for d in os.environ.get("APP_DIRS_STR", "").splitlines() if d]

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

itheme = Gtk.IconTheme.new()
itheme.set_custom_theme(theme_name)

try:
    with open(hist_path) as f:
        hist = json.load(f)
except Exception:
    hist = {}

def run(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    except Exception:
        return None

def safe_name(n):
    return re.sub(r"[^A-Za-z0-9._+-]", "_", n)

def cap_icon(name):
    """Shrink raster `name` >48px into the overlay. Name keeps working."""
    if not name or "/" in name:
        return
    try:
        info = itheme.lookup_icon(name, 256, Gtk.IconLookupFlags(0))
        src = info.get_filename() if info else None
    except Exception:
        src = None
    if not src or not os.path.isfile(src):
        return
    if src.lower().endswith((".svg", ".svgz")):
        return
    dest = os.path.join(overlay, safe_name(name) + ".png")
    try:
        if os.path.isfile(dest) and os.path.getmtime(dest) >= os.path.getmtime(src):
            return
    except OSError:
        pass
    r = run(["identify", "-format", "%w %h", src])
    if not r or r.returncode != 0:
        return
    try:
        w, h = map(int, r.stdout.strip().split())
    except ValueError:
        return
    if w <= 48 and h <= 48:
        return
    r = run(["magick", src, "-resize", "48x48>", dest])
    if not r or r.returncode != 0:
        print(f"launcher: magick failed for {src}", flush=True)

now = int(time.time())
seen = set()
apps = []
for d in dirs:
    if not os.path.isdir(d):
        continue
    for fn in sorted(os.listdir(d)):
        if not fn.endswith(".desktop") or fn in seen:
            continue
        path = os.path.join(d, fn)
        try:
            cp = configparser.ConfigParser(interpolation=None, strict=False)
            cp.optionxform = str
            with open(path, encoding="utf-8", errors="replace") as f:
                cp.read_file(f)
            e = cp["Desktop Entry"]
            if e.get("NoDisplay", "false").lower() == "true":
                continue
            if e.get("Hidden", "false").lower() == "true":
                continue
            name = (e.get("Name") or "").strip()
            if not name:
                continue
            exec_raw = (e.get("Exec") or "").strip()
            if not exec_raw:
                continue
            exec_clean = re.sub(r"%[fFuUdDnNiCckvm]", "", exec_raw).strip()
            terminal = (e.get("Terminal") or "false").strip().lower() == "true"
            icon = (e.get("Icon") or "application-x-executable").strip() or "application-x-executable"
            try:
                found = itheme.lookup_icon(icon, 16, Gtk.IconLookupFlags(0))
                if found is None and "/" not in icon:
                    icon = "application-x-executable"
            except Exception:
                pass
            cap_icon(icon)
            h = hist.get(fn, {})
            try:
                count = int(h.get("count", 0) or 0)
            except (TypeError, ValueError):
                count = 0
            try:
                last = int(h.get("last_used", 0) or 0)
            except (TypeError, ValueError):
                last = 0
            age_days = max(0, (now - last) / 86400) if last else 9999
            apps.append({
                "id": fn[:-len(".desktop")] if fn.endswith(".desktop") else fn, "name": name, "exec": exec_clean,
                "terminal": terminal, "icon": icon,
                "_score": (count * 100 - min(age_days, 365), name.lower()),
            })
            seen.add(fn)
        except Exception:
            continue

# most-used first, then alphabetical
apps.sort(key=lambda a: (-a["_score"][0], a["_score"][1]))
for a in apps:
    a.pop("_score", None)
print(json.dumps(apps))
EOF
}

do_launch() {
  local id="${1:-}"
  [[ -z "$id" ]] && { echo '{"error":"no app id"}' >&2; return 1; }
  [[ "$id" != *.desktop ]] && id="$id.desktop"

  local file=""
  while IFS= read -r d; do
    [[ -f "$d/$id" ]] && { file="$d/$id"; break; }
  done <<< "$APP_DIRS_STR"
  [[ -z "$file" ]] && { echo "{\"error\":\"app not found: $id\"}" >&2; return 1; }

  local exec_line is_terminal
  exec_line=$(grep -m1 '^Exec\s*=' "$file" | cut -d= -f2- | sed -E 's/%[fFuUdDnNiCckvm]//g' | xargs)
  [[ -z "$exec_line" ]] && { echo '{"error":"empty Exec"}' >&2; return 1; }
  grep -qim1 '^Terminal\s*=\s*true' "$file" && is_terminal=1 || is_terminal=0

  HISTORY_FILE="$HISTORY_FILE" APP_ID="$id" python3 -c '
import json, os, time
p = os.environ["HISTORY_FILE"]; i = os.environ["APP_ID"]
try:
    with open(p) as f: hist = json.load(f)
except Exception:
    hist = {}
e = hist.get(i, {})
try: e["count"] = int(e.get("count", 0)) + 1
except Exception: e["count"] = 1
e["last_used"] = int(time.time())
hist[i] = e
tmp = p + ".tmp"
with open(tmp, "w") as f: json.dump(hist, f)
os.replace(tmp, p)
'

  if [[ "$is_terminal" -eq 1 ]]; then
    if command -v kitty >/dev/null 2>&1; then
      kitty -d $HOME -e bash -c "$exec_line" &>/dev/null &
    else
      x-terminal-emulator -e bash -c "$exec_line" &>/dev/null &
    fi
  else
    if command -v gtk-launch >/dev/null 2>&1; then
      cd $HOME && gtk-launch "$id" &>/dev/null &
    else
      bash -c "$exec_line" &>/dev/null &
    fi
  fi

  close_ui 
}

close_ui() {
  command -v eww >/dev/null 2>&1 && {
    eww close launcher 2>/dev/null || true
    eww update launcher_query="" 2>/dev/null || true
    eww update files_json="[]" 2>/dev/null || true
    hyprctl dispatch 'hl.dsp.submap ("reset")'
  }
}

# files <query> — up to 20 files/dirs under $HOME matching <query>.
# Prints a JSON array: [{"name": basename, "path": full path}].
# Needs 2+ chars; noisy dirs pruned. Used by the launcher file section.
do_files() {
  local q="$1"
  if [[ "${#q}" -lt 2 ]]; then echo '[]'; return 0; fi
  if command -v fd >/dev/null 2>&1; then
    fd -H -F -t f -t d --max-results 20 \
      -E .cache -E .cargo -E .rustup -E .mozilla -E .local/share/Trash \
      -E node_modules -E .git -E __pycache__ \
      "$q" "$HOME" 2>/dev/null | head -n 20 | python3 -c '
import json, os, sys
out = []
for line in sys.stdin:
    p = line.rstrip("\n")
    if p:
        out.append({"name": os.path.basename(p.rstrip("/")), "path": p})
print(json.dumps(out))'
  else
    find "$HOME" \( -path "$HOME/.cache*" -o -path "$HOME/.mozilla*" \
      -o -name .git -o -name node_modules -o -name __pycache__ \) -prune \
      -o -iname "*$q*" -print 2>/dev/null | head -n 20 | python3 -c '
import json, os, sys
out = []
for line in sys.stdin:
    p = line.rstrip("\n")
    if p:
        out.append({"name": os.path.basename(p.rstrip("/")), "path": p})
print(json.dumps(out))'
  fi
}

case "${1:-list}" in
  list|"") do_list ;;
  launch|open|start) shift; do_launch "$@" ;;
  files) shift; do_files "${*:-}" ;;
  *) echo "usage: launcher.sh [list|launch <id>|files <query>]" >&2; exit 1 ;;
esac
