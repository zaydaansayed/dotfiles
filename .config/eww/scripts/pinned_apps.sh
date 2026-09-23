#!/bin/bash
# Pin management for the dock (no eww output — live data comes from apps.sh).
#   pinned_apps.sh add <app>  # pin a new app (appends to the right)
#   pinned_apps.sh rm <app>   # unpin an app
#   pinned_apps.sh move <app> +[N] | -[N]   # + moves right, - moves left (N defaults to 1)
#   pinned_apps.sh launch <app>             # focus the app if open, else launch it
#   pinned_apps.sh open <app>               # always open a new window (never focus)
#   pinned_apps.sh focus <address>          # focus one window by Hyprland address
#                                           # (+ record usage: count/last_used in
#                                           # the same history file launcher.sh uses)
#   pinned_apps.sh close <app>              # end task: close all windows of an
#                                           # open pinned or active app
#   pinned_apps.sh first | last             # id of first/last pinned app
#   pinned_apps.sh pos <app>                # 1-based position of an app
#   pinned_apps.sh is-first|is-last <app>   # "true"/"false" (exit 0/1)
# Order is stored in pinned_apps.conf in this same directory.
# apps.sh picks up every change automatically (inotify) and pushes it to eww.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${PINNED_APPS_FILE:-$SCRIPT_DIR/pinned_apps.conf}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/eww-launcher"
HISTORY_FILE="$CACHE_DIR/history.json"

declare -A PIN_MAP=(
  [obsidian]="obsidian.desktop"
  [spotify]="spotify-launcher.desktop"
  [yazi]="yazi.desktop"
  [firefox]="firefox.desktop"
)

APP_DIRS=(
  "$HOME/.local/share/applications"
  "$HOME/.local/share/flatpak/exports/share/applications"
  "/var/lib/flatpak/exports/share/applications"
  "/usr/local/share/applications"
  "/usr/share/applications"
)

usage() {
  echo "usage: $(basename "$0") [add <app>|rm <app>|move <app> +[N]|-[N]|launch <app>|open <app>|focus <address>|close <app>|first|last|pos <app>|is-first|is-last <app>]" >&2
}

do_launch() {
  local token="${1:-}"
  local force_new="${2:-false}"
  [[ -z "$token" ]] && { echo "usage: $(basename "$0") launch <app>" >&2; return 1; }

  local key file
  key=$(echo "$token" | tr '[:upper:]' '[:lower:]')
  [[ "$key" == *.desktop ]] && key="${key%.desktop}"
  if [[ -n "${PIN_MAP[$key]:-}" ]]; then
    file="${PIN_MAP[$key]}"
  else
    file="$key.desktop"
  fi

  local dir found=""
  for dir in "${APP_DIRS[@]}"; do
    if [[ -f "$dir/$file" ]]; then
      found="$dir/$file"
      break
    fi
  done
  if [[ -z "$found" ]]; then
    # tier 2+3: case-insensitive exact, then stem-tail match for dotless
    # tokens (thunderbird -> org.mozilla.Thunderbird.desktop)
    local lower want f stem tailonly=""
    want=$(echo "$file" | tr '[:upper:]' '[:lower:]')
    if [[ "$want" == *.desktop && "${want%.desktop}" != *.* ]]; then
      tailonly="${want%.desktop}"
    fi
    for dir in "${APP_DIRS[@]}"; do
      [[ -d "$dir" ]] || continue
      for f in "$dir"/*.desktop; do
        [[ -e "$f" ]] || continue
        lower=$(basename "$f" | tr '[:upper:]' '[:lower:]')
        if [[ "$lower" == "$want" ]]; then
          file=$(basename "$f")
          found="$f"
          break 2
        fi
      done
    done
    if [[ -z "$found" && -n "$tailonly" ]]; then
      for dir in "${APP_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        for f in "$dir"/*.desktop; do
          [[ -e "$f" ]] || continue
          lower=$(basename "$f" | tr '[:upper:]' '[:lower:]')
          stem="${lower%.desktop}"
          if [[ "${stem##*.}" == "$tailonly" ]]; then
            file=$(basename "$f")
            found="$f"
            break 2
          fi
        done
      done
    fi
  fi
  [[ -z "$found" ]] && { echo "{\"error\":\"app not found: $file\"}" >&2; return 1; }

  local exec_line is_terminal
  exec_line=$(grep -m1 '^Exec\s*=' "$found" | cut -d= -f2- | sed -E 's/%[fFuUdDnNiCckvm]//g' | xargs)
  [[ -z "$exec_line" ]] && { echo '{"error":"empty Exec"}' >&2; return 1; }
  grep -qim1 '^Terminal\s*=\s*true' "$found" && is_terminal=1 || is_terminal=0

  # If a window of this app is already open, focus it instead of launching
  # (unless force_new is true — "open" always spawns a new window).
  # (open/focused state lives in apps.sh, reused here)
  local focus_addr=""
  if [[ "$force_new" != "true" ]]; then
    focus_addr=$("$SCRIPT_DIR/apps.sh" view 2>/dev/null | jq -r --arg k "$key" '.pinned[]? | select(.id == $k and .active) | .focus_address // empty' | head -n1)
  fi

  mkdir -p "$CACHE_DIR"
  [[ -f "$HISTORY_FILE" ]] || echo '{}' > "$HISTORY_FILE"
  HISTORY_FILE="$HISTORY_FILE" APP_ID="$file" python3 -c '
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

  if [[ -n "$focus_addr" ]]; then
    hyprctl dispatch "hl.dsp.focus({ window = \"address:$focus_addr\" })" &>/dev/null || true
    return 0
  fi

  if [[ "$is_terminal" -eq 1 ]]; then
    if command -v kitty >/dev/null 2>&1; then
      kitty -d "$HOME" -e bash -c "$exec_line" &>/dev/null &
    else
      x-terminal-emulator -e bash -c "$exec_line" &>/dev/null &
    fi
  else
    if command -v gtk-launch >/dev/null 2>&1; then
      cd "$HOME" && gtk-launch "$file" &>/dev/null &
    else
      bash -c "$exec_line" &>/dev/null &
    fi
  fi
}

CMD="${1:-}"
if [[ -z "$CMD" ]]; then
  usage
  exit 1
fi
if [[ "$CMD" == "-h" || "$CMD" == "--help" || "$CMD" == "help" ]]; then
  usage
  exit 0
fi

if [[ "$CMD" == "launch" || "$CMD" == "start" ]]; then
  # support: launch --new <app>  and  launch <app> --new
  if [[ "${2:-}" == "--new" || "${2:-}" == "-n" ]]; then
    do_launch "${3:-}" true
  elif [[ "${3:-}" == "--new" || "${3:-}" == "-n" ]]; then
    do_launch "${2:-}" true
  else
    do_launch "${2:-}" false
  fi
  exit $?
fi

if [[ "$CMD" == "open" ]]; then
  do_launch "${2:-}" true
  exit $?
fi

if [[ "$CMD" == "focus" ]]; then
  addr="${2:-}"
  if [[ ! "$addr" =~ ^0x[0-9a-fA-F]+$ ]]; then
    echo "usage: $(basename "$0") focus <address>  (e.g. focus 0xabc123)" >&2
    exit 1
  fi
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" &>/dev/null
  exit $?
fi

if [[ "$CMD" == "close" || "$CMD" == "kill" || "$CMD" == "end" ]]; then
  APPS_SH="$SCRIPT_DIR/apps.sh" CMD="$CMD" ARG2="${2:-}" python3 - << 'EOF'
import json, os, subprocess, sys

key = (os.environ.get("ARG2", "") or "").strip().lower()
if key.endswith(".desktop"):
    key = key[:-len(".desktop")]
if not key:
    print("usage: pinned_apps.sh close <app>", file=sys.stderr)
    sys.exit(1)
try:
    data = json.loads(subprocess.check_output(
        [os.environ["APPS_SH"], "view"], timeout=30).decode())
except Exception as e:
    print(f"error: could not read app state: {e}", file=sys.stderr)
    sys.exit(1)

addrs = []
for p in data.get("pinned", []):
    if p["id"] == key and p["active"]:
        addrs = [w["address"] for w in p["windows"]]
        break
if not addrs:
    for a in data.get("active", []):
        desk = (a.get("desktop") or "").lower()
        if desk == key + ".desktop" or desk[:-8] == key or a.get("icon") == key:
            addrs = [w["address"] for w in a["windows"]]
            break
if not addrs:
    print(f"not open: {key}")
    sys.exit(1)
failed = 0
for addr in addrs:
    r = subprocess.run(["hyprctl", "dispatch", f"hl.dsp.window.close({{ window = \"address:{addr}\" }})"],
                       capture_output=True, timeout=15)
    if r.returncode != 0:
        failed += 1
if failed:
    print(f"closed {len(addrs) - failed}/{len(addrs)} windows of {key}", file=sys.stderr)
    sys.exit(1)
print(f"closed {len(addrs)} window(s) of {key}")
EOF
  exit $?
fi

# --- conf queries and list mutations share one python helper ---
if [[ "$CMD" == "add" || "$CMD" == "rm" || "$CMD" == "move" || "$CMD" == "pos" || "$CMD" == "position" || "$CMD" == "first" || "$CMD" == "last" || "$CMD" == "is-first" || "$CMD" == "is-last" ]]; then
  CONFIG="$CONFIG" CMD="$CMD" ARG2="${2:-}" ARG3="${3:-}" python3 - << 'EOF'
import os, re, sys

apps = {
    "obsidian": "obsidian.desktop",
    "spotify": "spotify-launcher.desktop",
    "yazi": "yazi.desktop",
    "firefox": "firefox.desktop",
}
dirs = [
    os.path.expanduser("~/.local/share/applications"),
    os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
    "/var/lib/flatpak/exports/share/applications",
    "/usr/local/share/applications",
    "/usr/share/applications",
]

def norm(token):
    t = token.strip().lower()
    if t.endswith(".desktop"):
        t = t[:-len(".desktop")]
    return t

def resolve(token):
    return apps.get(token, token + ".desktop")

def find_file(filename):
    for d in dirs:
        p = os.path.join(d, filename)
        if os.path.isfile(p):
            return p
    # tier 2: case-insensitive exact match
    want = filename.lower()
    tail_candidate = ""
    if want.endswith(".desktop"):
        tail_candidate = want[:-len(".desktop")]
    for d in dirs:
        try:
            files = os.listdir(d)
        except OSError:
            continue
        for fn in files:
            if fn.lower() == want:
                return os.path.join(d, fn)
        # tier 3: stem-tail match, only for dotless tokens
        # (thunderbird -> org.mozilla.Thunderbird.desktop)
        if tail_candidate and "." not in tail_candidate:
            for fn in files:
                low = fn.lower()
                if low.endswith(".desktop") and low[:-len(".desktop")].split(".")[-1] == tail_candidate:
                    return os.path.join(d, fn)
    return None

def is_active(line):
    s = line.strip()
    return bool(s) and not s.startswith("#")

cfg = os.environ.get("CONFIG", "")
cmd = os.environ.get("CMD", "")
arg2 = os.environ.get("ARG2", "")
arg3 = os.environ.get("ARG3", "")

try:
    with open(cfg, encoding="utf-8") as f:
        lines = f.readlines()
    conf_found = True
except FileNotFoundError:
    lines = []
    conf_found = False

def active_positions():
    return [i for i, l in enumerate(lines) if is_active(l)]

def save():
    with open(cfg, "w", encoding="utf-8") as f:
        f.writelines(lines)

if cmd == "add":
    if not arg2:
        print("usage: pinned_apps.sh add <app>", file=sys.stderr)
        sys.exit(1)
    key = norm(arg2)
    if not key:
        print("error: empty app name", file=sys.stderr)
        sys.exit(1)
    path = find_file(resolve(key))
    if path:
        real_stem = os.path.basename(path)[:-len(".desktop")].lower()
    else:
        real_stem = ""
    # canonical conf id: keep friendly tokens (PIN_MAP hits, exact files),
    # otherwise store the real file's stem so apps.sh always resolves it
    if key in apps or (path and os.path.basename(path).lower() == resolve(key).lower()):
        store = key
    elif path:
        store = real_stem
        print(f"note: pinning as '{store}' (from {os.path.basename(path)})")
    else:
        store = key
        print(f"warning: no .desktop file found for '{key}', adding anyway", file=sys.stderr)
    existing = [norm(lines[i]) for i in active_positions()]
    existing_files = set()
    for t in existing:
        p = find_file(resolve(t))
        if p:
            existing_files.add(os.path.basename(p).lower())
    dup = store in existing or (real_stem and (real_stem + ".desktop") in existing_files)
    if dup:
        print(f"already pinned: {store}")
        sys.exit(0)
    if lines and not lines[-1].endswith("\n"):
        lines[-1] += "\n"
    lines.append(store + "\n")
    save()
    print(f"added at position {len(active_positions())}: {store}")

elif cmd == "rm":
    if not arg2:
        print("usage: pinned_apps.sh rm <app>", file=sys.stderr)
        sys.exit(1)
    key = norm(arg2)
    pos = active_positions()
    hit = [i for i in pos if norm(lines[i]) == key]
    if not hit:
        print(f"not pinned: {key}")
        sys.exit(1)
    for i in reversed(hit):
        del lines[i]
    save()
    print(f"removed: {key}")

elif cmd == "move":
    if not arg2 or not arg3:
        print("usage: pinned_apps.sh move <app> +[N]|-[N]   (+ right, - left)", file=sys.stderr)
        sys.exit(1)
    key = norm(arg2)
    m = re.fullmatch(r"([+-])(\d*)", arg3.strip())
    if not m:
        print("usage: pinned_apps.sh move <app> +[N]|-[N]   (+ right, - left)", file=sys.stderr)
        sys.exit(1)
    delta = int(m.group(2) or 1) * (1 if m.group(1) == "+" else -1)
    pos = active_positions()
    hit = [i for i in pos if norm(lines[i]) == key]
    if not hit:
        print(f"not pinned: {key}")
        sys.exit(1)
    idx = hit[0]
    old_rank = pos.index(idx)
    new_rank = min(max(old_rank + delta, 0), len(pos) - 1)
    if new_rank == old_rank:
        print(f"already at the {'right' if delta > 0 else 'left'} end (position {old_rank + 1}): {key}")
        sys.exit(0)
    moving = lines.pop(idx)
    if not moving.endswith("\n"):
        moving += "\n"
    rest = [i for i, l in enumerate(lines) if is_active(l)]
    if new_rank >= len(rest):
        if lines and not lines[-1].endswith("\n"):
            lines[-1] += "\n"
        lines.append(moving)
    else:
        lines.insert(rest[new_rank], moving)
    save()
    print(f"moved {key}: position {old_rank + 1} -> {new_rank + 1}")

elif cmd in ("pos", "position", "first", "last", "is-first", "is-last"):
    def ordered_ids():
        ids = [norm(lines[i]) for i in active_positions()]
        if not ids and not conf_found:
            ids = list(apps)
        seen_q = set()
        out_q = []
        for t in ids:
            if t not in seen_q:
                seen_q.add(t)
                out_q.append(t)
        return out_q

    ids = ordered_ids()
    if cmd in ("pos", "position"):
        if not arg2:
            print("usage: pinned_apps.sh pos <app>", file=sys.stderr)
            sys.exit(1)
        key = norm(arg2)
        if key in ids:
            print(ids.index(key) + 1)
        else:
            print(f"not pinned: {key}", file=sys.stderr)
            sys.exit(1)
    elif cmd in ("first", "last"):
        if not ids:
            print("no pinned apps", file=sys.stderr)
            sys.exit(1)
        print(ids[0] if cmd == "first" else ids[-1])
    else:  # is-first / is-last
        if not arg2:
            print(f"usage: pinned_apps.sh {cmd} <app>", file=sys.stderr)
            sys.exit(1)
        key = norm(arg2)
        edge = (ids[0] if cmd == "is-first" else ids[-1]) if ids else None
        ok = edge is not None and edge == key
        print("true" if ok else "false")
        sys.exit(0 if ok else 1)
EOF
  exit $?
fi

echo "error: unknown command '$CMD'" >&2
usage
exit 1
