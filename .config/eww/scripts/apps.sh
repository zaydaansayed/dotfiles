#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PINNED_CONF="${PINNED_APPS_FILE:-$SCRIPT_DIR/pinned_apps.conf}"

apps_python() {
PINNED_CONF="$PINNED_CONF" PRETTY="$1" APPS_MODE="$2" python3 - << 'PYEOF'
import json, os, re, select, subprocess, sys, time

MODE = os.environ.get("APPS_MODE", "once")

# --- test hooks: point these at fixture files to test without Hyprland ---
def load(cmd, override):
    path = os.environ.get(override, "")
    if path:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    return json.loads(subprocess.check_output(cmd).decode())

def fetch_state():
    clients = load(["hyprctl", "-j", "clients"], "CLIENTS_JSON")
    active_win = load(["hyprctl", "-j", "activewindow"], "ACTIVEWINDOW_JSON")
    monitors = load(["hyprctl", "-j", "monitors"], "MONITORS_JSON")
    focused = None
    for m in monitors:
        if m.get("focused") and isinstance(m.get("activeWorkspace"), dict):
            aw = m["activeWorkspace"]
            if aw.get("id") is not None:
                focused = {"id": aw["id"], "monitorID": m["id"]}
                break
    if focused is None:
        focused = load(["hyprctl", "-j", "activeworkspace"], "ACTIVEWS_JSON")
    return clients, active_win, monitors, focused

TERMINALS = {"kitty", "alacritty", "foot", "wezterm", "st", "xterm",
             "org.wezfurlong.wezterm"}
SHELLS = {"bash", "zsh", "fish", "sh", "kitten", "kitty"}

def terminal_child(ppid):
    """Deepest foreground-ish process name under a terminal pid."""
    try:
        with open(f"/proc/{ppid}/task/{ppid}/children") as f:
            kids = [int(x) for x in f.read().split()]
        if not kids:
            return ""
        child = max(kids)
        with open(f"/proc/{child}/comm") as f:
            proc = f.read().strip()
        if proc in SHELLS:
            try:
                with open(f"/proc/{child}/task/{child}/children") as f:
                    sub = [int(x) for x in f.read().split()]
                if sub:
                    with open(f"/proc/{max(sub)}/comm") as f:
                        return f.read().strip()
            except OSError:
                pass
        return proc
    except (OSError, ValueError):
        return ""

def tail_token(s):
    s = (s or "").lower()
    return s.split(".")[-1] if "." in s else s

def fallback_icon(low):
    if "obs" in low or "obsproject" in low:
        return "com.obsproject.Studio"
    return tail_token(low)

def identify(lookup, title, pid):
    """A live window -> (desktop entry or None, icon name)."""
    low = (lookup or "").lower()
    if low in TERMINALS:
        cmd = terminal_child(pid) if pid and pid > 0 else ""
        eff = ""
        if not cmd or cmd in SHELLS:
            tl = (title or "").lower()
            if "nvim" in tl or "neovim" in tl:
                eff = "nvim"
            else:
                for key in ("yazi", "btop", "htop", "ranger", "tmux"):
                    if key in tl:
                        eff = key
                        break
        else:
            eff = cmd.lower()
        if eff:
            d = by_exec.get(eff) or by_stem.get(eff) or by_tail.get(eff.split(".")[-1])
            return d, (d["icon"] or "kitty") if d else "kitty"
        d = by_wmclass.get(low) or by_stem.get(low)
        return d, (d["icon"] or "kitty") if d else "kitty"
    d = by_wmclass.get(low)
    if d is None and "." in low:
        d = by_tail.get(low.split(".")[-1])
    if d is None:
        d = by_stem.get(low)
    if d is None:
        d = by_file.get(low.split(".")[-1] + ".desktop")
    icon = d["icon"] if d and d.get("icon") else fallback_icon(low)
    return d, icon


# --- pinned order ---
PIN_MAP = {
    "obsidian": "obsidian.desktop",
    "spotify": "spotify-launcher.desktop",
    "yazi": "yazi.desktop",
    "firefox": "firefox.desktop",
}

def pinned_order():
    order, seen = [], set()
    try:
        with open(os.environ.get("PINNED_CONF", ""), encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                key = line.lower()
                if key.endswith(".desktop"):
                    key = key[:-len(".desktop")]
                if key not in seen:
                    seen.add(key)
                    order.append(key)
    except FileNotFoundError:
        order = list(PIN_MAP)

    def resolve_pin(key):
        if key in PIN_MAP:
            return PIN_MAP[key]
        if (key + ".desktop") in by_file:
            return key + ".desktop"
        if "." not in key:
            e = by_tail.get(key)
            if e:
                return e["file"]
        return key + ".desktop"

    return [(key, resolve_pin(key)) for key in order]

# --- support fns shared by once/daemon paths (pure python, no globals) ---
APP_DIRS = [
    os.path.expanduser("~/.local/share/applications"),
    os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
    "/var/lib/flatpak/exports/share/applications",
    "/usr/local/share/applications",
    "/usr/share/applications",
]

# --- .desktop database (fast manual scan; replaces the old Gio index) ---
WANT_KEYS = {"Name", "Icon", "Exec", "TryExec", "StartupWMClass", "Terminal"}

def parse_desktop(path):
    """Only the [Desktop Entry] section; first occurrence wins."""
    try:
        entry, in_entry = {}, False
        with open(path, encoding="utf-8", errors="replace") as f:
            for line in f:
                s = line.strip()
                if s.startswith("["):
                    in_entry = (s == "[Desktop Entry]")
                    continue
                if not in_entry or "=" not in s:
                    continue
                k, _, v = s.partition("=")
                k = k.strip()
                if k in WANT_KEYS and k not in entry:
                    entry[k] = v.strip()
        return entry or None
    except OSError:
        return None

def exec_base(exec_line):
    first = (exec_line or "").strip().split()
    if not first:
        return ""
    return os.path.basename(first[0]).lower()

desktops, seen_files = [], set()
for d in APP_DIRS:
    try:
        files = sorted(os.listdir(d))
    except OSError:
        continue
    for fn in files:
        if not fn.endswith(".desktop") or fn in seen_files:
            continue
        entry = parse_desktop(os.path.join(d, fn))
        if not entry:
            continue
        seen_files.add(fn)
        raw_exec = entry.get("Exec", "")
        clean = re.sub(r"%[fFuUdDnNiCckvm]", "", raw_exec).strip()
        low = fn.lower()
        desktops.append({
            "file": fn,
            "stem": low[:-len(".desktop")],
            "name": (entry.get("Name") or "").strip(),
            "icon": (entry.get("Icon") or "").strip(),
            "exec": clean,
            "terminal": (entry.get("Terminal") or "false").strip().lower() == "true",
            "wmclass": (entry.get("StartupWMClass") or "").strip().lower(),
            "execbase": exec_base(raw_exec),
            "tryexec": os.path.basename((entry.get("TryExec") or "").strip()).lower(),
        })

by_stem, by_wmclass, by_exec, by_file, by_tail = {}, {}, {}, {}, {}
for e in desktops:
    by_file[e["file"].lower()] = e
    by_stem.setdefault(e["stem"], e)
    by_tail.setdefault(e["stem"].split(".")[-1], e)
    if e["wmclass"]:
        by_wmclass.setdefault(e["wmclass"], e)
    if e["execbase"]:
        by_exec.setdefault(e["execbase"], e)
    if e["tryexec"]:
        by_exec.setdefault(e["tryexec"], e)

def stem(fn):
    return fn[:-len(".desktop")] if fn.endswith(".desktop") else fn

def live_state():
    """Fetch Hyprland state; returns (clients, active_win, monitors, active_ws, focused_address)."""
    c, aw, mons, aws = fetch_state()
    awd = aw or {}
    fa = awd.get("address", "none") if isinstance(awd, dict) else "none"
    return c, aw, mons, aws, fa
def build_snapshot(clients_l, focused_addr, monitors_l, active_ws_l, order_l):
    """Full dock model from already-fetched state. Returns the result dict."""
    def match_pin(dstems, icon):
        for key, fn in order_l:
            if stem(fn) in dstems or key in dstems or key == icon:
                return key
        return ""

    groups, group_idx = [], {}
    for c in clients_l:
        if not c.get("mapped", False) or c.get("hidden", False):
            continue
        lookup = ((c.get("initialClass") or c.get("class")) or "")
        title = c.get("title", "")
        pid = c.get("pid", 0) or 0
        dent, icon = identify(lookup, title, pid)
        key = dent["stem"] if dent else icon
        addr = c.get("address", "")
        is_focused = (addr == focused_addr)
        win = {"address": addr, "pid": pid, "title": title,
               "focused": is_focused,
               "_hist": c.get("focusHistoryID", 10 ** 9)}
        if key in group_idx:
            g = groups[group_idx[key]]
            g["_windows"].append(win)
            g["_dstems"].add(dent["stem"] if dent else "")
            if is_focused:
                g["focused"] = True
        else:
            group_idx[key] = len(groups)
            groups.append({"key": key, "icon": icon, "focused": is_focused,
                           "dent": dent,
                           "_dstems": {dent["stem"]} if dent else set(),
                           "_windows": [win]})
    for g in groups:
        g["_windows"].sort(key=lambda w: w["_hist"])
        g["pin"] = match_pin(g["_dstems"], g["icon"])

    def finalize(wins):
        titles = [w["title"] for w in wins]
        for w in wins:
            w.pop("_hist", None)
        if not wins:
            tooltip = ""
        elif len(titles) == 1:
            tooltip = titles[0]
        else:
            tooltip = f"{len(titles)} windows:\n" + "\n".join(titles)
        return {
            "focus_address": wins[0]["address"] if wins else "",
            "count": len(wins),
            "tooltip": tooltip,
            "windows": wins,
        }

    pinned_apps = []
    for key, fn in order_l:
        dent = by_file.get(fn.lower())
        wins = []
        for g in groups:
            if g["pin"] == key:
                wins.extend(g["_windows"])
        wins.sort(key=lambda w: w["_hist"])
        entry = {"id": key}
        if dent:
            entry.update({"name": dent["name"], "icon": dent["icon"],
                          "exec": dent["exec"], "terminal": dent["terminal"],
                          "desktop": dent["file"]})
        else:
            entry.update({"name": key, "icon": "", "exec": "",
                          "terminal": False, "desktop": "",
                          "error": f"not found: {fn}"})
        entry["active"] = bool(wins)
        entry["focused"] = any(w["focused"] for w in wins)
        entry.update(finalize(wins))
        pinned_apps.append(entry)

    active = []
    for g in groups:
        if g["pin"] != "":
            continue
        dent = g["dent"]
        item = {"desktop": dent["file"] if dent else "",
                "name": dent["name"] if dent and dent.get("name") else g["icon"],
                "icon": g["icon"], "focused": g["focused"]}
        item.update(finalize(g["_windows"]))
        active.append(item)
    active.sort(key=lambda a: (a["name"] or a["icon"]).lower())

    focused_icon = ""
    for g in groups:
        if g["focused"]:
            focused_icon = g["icon"]
            break

    def dock_clear():
        try:
            strip = 70
            ws_id = active_ws_l.get("id")
            mon_id = active_ws_l.get("monitorID")
            mon = next((m for m in monitors_l if m.get("id") == mon_id), None)
            if ws_id is None or mon is None:
                return True
            top = mon.get("y", 0) + mon.get("height", 0) / (mon.get("scale") or 1) - strip
            for c in clients_l:
                if not c.get("mapped", False) or c.get("hidden", False):
                    continue
                if c.get("monitor") != mon_id:
                    continue
                ws = c.get("workspace") or {}
                if ws.get("id") != ws_id and not c.get("pinned", False):
                    continue
                at, size = c.get("at", [0, 0]), c.get("size", [0, 0])
                if at[1] + size[1] > top and at[1] < top + strip:
                    return False
            return True
        except Exception:
            return True

    return {
        "pinned": pinned_apps,
        "active": active,
        "is_first": order_l[0][0] if order_l else "",
        "is_last": order_l[-1][0] if order_l else "",
        "focused": focused_icon,
        "dock_clear": dock_clear(),
    }

def snapshot_once(pretty):
    """One-shot path (view/CLI): fetch, build, print."""
    c, aw, mons, aws, fa = live_state()
    order_l = pinned_order()
    print(json.dumps(build_snapshot(c, fa, mons, aws, order_l),
                     indent=2 if pretty else None))

def run_daemon(pretty):
    """Persistent path: load once, then recompute+print on socket/conf activity."""
    import selectors
    order_l = pinned_order()
    try:
        conf_stat = os.stat(os.environ.get("PINNED_CONF", ""))
        conf_key = (conf_stat.st_mtime_ns, conf_stat.st_size)
    except OSError:
        conf_key = None

    def emit():
        c, aw, mons, aws, fa = live_state()
        print(json.dumps(build_snapshot(c, fa, mons, aws, order_l),
                         indent=2 if pretty else None), flush=True)

    emit()
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    sock_path = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"),
                             "hypr", sig, ".socket2.sock") if sig else ""
    sel = selectors.DefaultSelector()
    sock = None
    buf = b""
    pending = False
    last_emit = time.monotonic()
    BURST_QUIET = 0.08
    CONF_POLL = 0.25

    def sock_connect():
        import socket as pysock
        s = pysock.socket(pysock.AF_UNIX, pysock.SOCK_STREAM)
        s.setblocking(False)
        try:
            s.connect(sock_path)
        except BlockingIOError:
            pass
        return s

    while True:
        if sock is None:
            if not sock_path or not os.path.exists(sock_path):
                time.sleep(0.5)
                try:
                    cur = os.stat(os.environ.get("PINNED_CONF", ""))
                    cur_key = (cur.st_mtime_ns, cur.st_size)
                except OSError:
                    cur_key = None
                if cur_key != conf_key:
                    conf_key = cur_key
                    order_l = pinned_order()
                    emit()
                continue
            try:
                sock = sock_connect()
                sel.register(sock, selectors.EVENT_READ)
            except OSError:
                sock = None
                time.sleep(0.5)
                continue
        try:
            events = sel.select(timeout=CONF_POLL)
        except Exception:
            events = []
        now = time.monotonic()
        for key, mask in events:
            try:
                chunk = key.fileobj.recv(65536)
            except (BlockingIOError, OSError):
                chunk = b""
            if not chunk:
                try:
                    sel.unregister(sock)
                except Exception:
                    pass
                try:
                    sock.close()
                except Exception:
                    pass
                sock = None
                buf = b""
                break
            buf += chunk
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                try:
                    text = line.decode(errors="replace")
                except Exception:
                    continue
                if ("openwindow" in text or "closewindow" in text
                        or "activewindow" in text or "workspace" in text
                        or "movewindow" in text or "fullscreen" in text
                        or "changefloatingmode" in text):
                    pending = True
        # burst coalescing: only recompute after a quiet window
        if pending and (not events or now - last_emit >= BURST_QUIET):
            try:
                cur = os.stat(os.environ.get("PINNED_CONF", ""))
                cur_key = (cur.st_mtime_ns, cur.st_size)
            except OSError:
                cur_key = None
            if cur_key != conf_key:
                conf_key = cur_key
                order_l = pinned_order()
            emit()
            pending = False
            last_emit = time.monotonic()
        else:
            try:
                cur = os.stat(os.environ.get("PINNED_CONF", ""))
                cur_key = (cur.st_mtime_ns, cur.st_size)
            except OSError:
                cur_key = None
            if cur_key != conf_key:
                conf_key = cur_key
                order_l = pinned_order()
                emit()
                last_emit = time.monotonic()

if MODE == "daemon":
    run_daemon(os.environ.get("PRETTY", "0") == "1")
else:
    snapshot_once(os.environ.get("PRETTY", "0") == "1")
PYEOF
}

print_state() {
  apps_python "$1" once
}

if [[ "${1:-}" == "view" ]]; then
  print_state 1
  exit 0
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" ]]; then
  echo "usage: $(basename "$0") [view]" >&2
  echo "  (no args = listen mode for 'deflisten apps' in eww)" >&2
  exit 0
fi

if [[ -n "${1:-}" ]]; then
  echo "error: unknown command '$1' (see '$0 help')" >&2
  exit 1
fi

daemon_body() {
  apps_python 0 daemon
}

trap 'kill $DPID 2>/dev/null' EXIT
while true; do
  daemon_body &
  DPID=$!
  wait $DPID
  sleep 0.5
done
