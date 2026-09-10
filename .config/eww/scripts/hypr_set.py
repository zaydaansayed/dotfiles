#!/usr/bin/env python3
"""hypr_set.py — settings > System action helper (called via hypr_set.sh).

Applies a Hyprland option live with `hyprctl keyword` AND patches the lua
module so it survives a Hyprland reload/restart. No raw file editing needed.
"""
import re
import subprocess
import sys
from pathlib import Path

MOD = Path.home() / "dotfiles/.config/hypr/modules"


def keyword(opt: str, val: str) -> None:
    subprocess.run(["hyprctl", "keyword", opt, val], check=False,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def patch(path: Path, pattern: str, repl: str, count: int = 1) -> None:
    text = path.read_text()
    new, n = re.subn(pattern, repl, text, count=count, flags=re.MULTILINE)
    if n:
        path.write_text(new)


def patch_block(path: Path, block_start: str, key_pat: str, repl: str) -> None:
    """Replace key_pat with repl on the first matching line inside the first
    { ... } block that opens on/after the block_start line. Blocks here are
    flat key-value tables, so a simple depth counter is enough."""
    lines = path.read_text().splitlines(keepends=True)
    start = next((i for i, line in enumerate(lines) if re.search(block_start, line)), None)
    if start is None:
        return
    depth, started = 0, False
    for i in range(start, len(lines)):
        depth += lines[i].count("{") - lines[i].count("}")
        if "{" in lines[i]:
            started = True
        if started and re.search(key_pat, lines[i]):
            lines[i] = re.sub(key_pat, repl, lines[i], count=1)
            break
        if started and depth <= 0:
            break
    path.write_text("".join(lines))


def setcursor(theme: str, size: str) -> None:
    subprocess.run(["hyprctl", "setcursor", theme, size], check=False,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def bool_str(v: str) -> str:
    return "true" if v.lower() in ("true", "1", "yes", "on") else "false"


def notify() -> None:
    """Touch the trigger file so the hypr_state deflisten re-emits instantly
    instead of waiting for its 30s freshness tick."""
    try:
        Path("/tmp/eww_hypr_state.trigger").touch()
    except OSError:
        pass


def main() -> None:
    if len(sys.argv) < 3:
        print("usage: hypr_set.sh <key> <value>")
        sys.exit(1)
    key, val = sys.argv[1], sys.argv[2]
    look = MOD / "look_feel.lua"
    inp = MOD / "input_keybinds.lua"
    env = MOD / "env_variables.lua"
    mon = MOD / "monitors.lua"
    misc = MOD / "misc.lua"
    auto = MOD / "autostart.lua"

    if key == "gaps_in":
        keyword("general:gaps_in", val)
        patch(look, r"gaps_in\s*=\s*\d+", f"gaps_in  = {val}")
    elif key == "gaps_out":
        keyword("general:gaps_out", val)
        patch(look, r"gaps_out\s*=\s*\d+", f"gaps_out = {val}")
    elif key == "border_size":
        keyword("general:border_size", val)
        patch(look, r"border_size\s*=\s*\d+", f"border_size = {val}")
    elif key == "rounding":
        keyword("decoration:rounding", val)
        patch(look, r"rounding\s*=\s*\d+", f"rounding       = {val}")
    elif key == "active_opacity":
        f = int(val) / 100
        keyword("decoration:active_opacity", str(f))
        patch(look, r"active_opacity\s*=\s*[\d.]+", f"active_opacity   = {f}")
    elif key == "inactive_opacity":
        f = int(val) / 100
        keyword("decoration:inactive_opacity", str(f))
        patch(look, r"inactive_opacity\s*=\s*[\d.]+", f"inactive_opacity = {f}")
    elif key == "blur":
        b = bool_str(val)
        keyword("decoration:blur:enabled", b)
        patch_block(look, r"blur\s*=\s*\{", r"enabled\s*=\s*\w+", f"enabled   = {b}")
    elif key == "shadow":
        b = bool_str(val)
        keyword("decoration:shadow:enabled", b)
        patch_block(look, r"shadow\s*=\s*\{", r"enabled\s*=\s*\w+", f"enabled      = {b}")
    elif key == "anims":
        b = bool_str(val)
        keyword("animations:enabled", b)
        patch_block(look, r"animations\s*=\s*\{", r"enabled\s*=\s*\w+", f"enabled = {b}")
    elif key == "tearing":
        b = bool_str(val)
        keyword("general:allow_tearing", b)
        patch(look, r"allow_tearing\s*=\s*\w+", f"allow_tearing = {b}")
    elif key == "sensitivity":
        f = int(val) / 100
        keyword("input:sensitivity", str(f))
        patch(inp, r"sensitivity\s*=\s*[-\d.]+", f"sensitivity = {f}")
    elif key == "nat_scroll":
        b = bool_str(val)
        keyword("input:touchpad:natural_scroll", b)
        patch_block(inp, r"touchpad\s*=\s*\{", r"natural_scroll\s*=\s*\w+", f"natural_scroll = {b}")
    elif key == "tap_click":
        b = bool_str(val)
        keyword("input:touchpad:tap_to_click", b)
        patch_block(inp, r"touchpad\s*=\s*\{", r"tap_to_click\s*=\s*\w+", f"tap_to_click = {b}")
    elif key == "cursor_size":
        theme = "Bibata-Modern-Classic"
        m = re.search(r'HYPRCURSOR_THEME",\s*"([^"]+)', env.read_text())
        if m:
            theme = m.group(1)
        setcursor(theme, val)
        patch(env, r'(XCURSOR_SIZE",\s*")[0-9]+(")', rf"\g<1>{val}\g<2>")
        patch(env, r'(HYPRCURSOR_SIZE",\s*")[0-9]+(")', rf"\g<1>{val}\g<2>")
    elif key == "gtk_theme":
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface",
                        "gtk-theme", val], check=False)
        patch(env, r'(GTK_THEME",\s*")[^"]+(")', rf"\g<1>{val}\g<2>")
    elif key == "scale":
        name = sys.argv[3] if len(sys.argv) > 3 else "eDP-1"
        keyword("monitor", f"{name},preferred,auto,{val}")
        patch(mon, r'scale\s*=\s*"[0-9.]+"', f'scale    = "{val}"')
    elif key == "logo":
        b = bool_str(val)
        keyword("misc:disable_hyprland_logo", b)
        patch(misc, r"disable_hyprland_logo\s*=\s*\w+", f"disable_hyprland_logo   = {b}")
    elif key == "autostart_toggle":
        # val = 1-based line number in autostart.lua; toggles leading "--"
        try:
            n = int(val)
        except ValueError:
            sys.exit(0)
        lines = auto.read_text().splitlines(keepends=True)
        if 1 <= n <= len(lines):
            line = lines[n - 1]
            stripped = line.lstrip()
            indent = line[: len(line) - len(stripped)]
            if stripped.startswith("--"):
                lines[n - 1] = indent + stripped[2:].lstrip()
            elif "hl.exec_cmd" in line:
                lines[n - 1] = indent + "-- " + stripped
            auto.write_text("".join(lines))
    else:
        print(f"unknown key: {key}")
        sys.exit(1)

    notify()


if __name__ == "__main__":
    main()
