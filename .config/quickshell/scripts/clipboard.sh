#!/bin/bash
set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/eww-clipboard"
mkdir -p "$CACHE_DIR"
LIMIT="${2:-0}"

do_list() {
  local limit="${1:-0}"
  CLIP_LIMIT="$limit" CACHE_DIR="$CACHE_DIR" python3 - << 'EOF'
import json, os, re, subprocess

limit = int(os.environ.get("CLIP_LIMIT", "0"))
cache = os.environ.get("CACHE_DIR", os.path.expanduser("~/.cache/eww-clipboard"))
os.makedirs(cache, exist_ok=True)

try:
    p = subprocess.run(["cliphist", "list"], capture_output=True, text=True, timeout=10)
    lines = p.stdout.splitlines()
except Exception:
    lines = []

out = []
img_re = re.compile(r"\[\[\s*binary data.*?\]\]")

if limit > 0:
    lines = lines[:limit]
for line in lines:
    if "\t" not in line:
        continue
    sid, preview = line.split("\t", 1)
    try:
        cid = int(sid.strip())
    except ValueError:
        continue
    preview = preview.strip()
    is_image = bool(img_re.search(preview))

    entry = {"id": cid, "preview": preview[:500], "type": "text", "image": ""}

    if is_image:
        entry["type"] = "image"
        dest = os.path.join(cache, f"{cid}.png")
        # (re)generate preview only if missing or empty
        if (not os.path.isfile(dest)) or os.path.getsize(dest) == 0:
            try:
                dec = subprocess.run(["cliphist", "decode", str(cid)],
                                     capture_output=True, timeout=15)
                if dec.returncode == 0 and dec.stdout:
                    tmp = dest + ".tmp"
                    with open(tmp, "wb") as f:
                        f.write(dec.stdout)
                    # normalize to a small png preview so eww stays fast
                    # (display size is 160x90, no point caching bigger)
                    r = subprocess.run(
                        ["magick", tmp, "-resize", "160x160>", dest],
                        capture_output=True, timeout=15)
                    if r.returncode != 0 or not os.path.isfile(dest):
                        # magick missing/failed: keep raw if it's already png
                        try:
                            os.replace(tmp, dest)
                        except OSError:
                            pass
                    else:
                        try:
                            os.remove(tmp)
                        except OSError:
                            pass
            except Exception:
                pass
        if os.path.isfile(dest):
            entry["image"] = dest
        else:
            # decode failed (entry pruned) — still show row, no preview
            entry["image"] = ""
    out.append(entry)

print(json.dumps(out))
EOF
}

do_copy() {
  local id="${1:-}"
  [[ -z "$id" ]] && { echo "usage: clipboard.sh copy <id>" >&2; exit 1; }
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT
  cliphist decode "$id" > "$tmp" || { echo "decode failed for $id" >&2; exit 1; }
  mime=$(file --mime-type -b "$tmp" 2>/dev/null || echo "text/plain")
  if [[ "$mime" == image/* ]]; then
    wl-copy -t "$mime" < "$tmp"
  else
    wl-copy < "$tmp"
  fi
  eww close clipboard
  hyprctl dispatch 'hl.dsp.submap ("reset")'
}

do_listen() {
  local limit="${1:-50}" prev="" out=""
  local db="${CLIPHIST_DB:-$HOME/.cache/cliphist/db}"
  local fp="" last_fp=""
  while true; do
    fp=$(stat -c '%Y:%s' "$db" 2>/dev/null || echo "missing")
    if [[ "$fp" != "$last_fp" || -z "$prev" ]]; then
      last_fp="$fp"
      if out=$(do_list "$limit" 2>/dev/null); then
        if [[ "$out" != "$prev" ]]; then
          printf '%s\n' "$out"
          prev="$out"
        fi
      fi
    fi
    sleep 1
  done
}

do_delete() {
  local id="${1:-}"
  [[ -z "$id" ]] && { echo "usage: clipboard.sh delete <id>" >&2; exit 1; }
  echo "$id" | cliphist delete
  rm -f "$CACHE_DIR/${id}.png"
  refresh_eww
}

do_wipe() {
  cliphist wipe
  rm -f "$CACHE_DIR"/*.png
  refresh_eww
}

refresh_eww() {
  local limit="${CLIP_LIST_LIMIT:-50}" snap
  if snap=$(do_list "$limit" 2>/dev/null) && [[ -n "$snap" ]]; then
    eww update clipboard_list="$snap" 2>/dev/null || true
  fi
}

case "${1:-list}" in
  list) do_list "${2:-50}" ;;
  listen) do_listen "${2:-50}" ;;
  copy) shift; do_copy "$@" ;;
  delete|del|rm) shift; do_delete "$@" ;;
  wipe|clear) do_wipe ;;
  *) echo "usage: clipboard.sh [list [limit]|listen [limit]|copy <id>|delete <id>|wipe]" >&2; exit 1 ;;
esac
