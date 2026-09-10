#!/usr/bin/env python3
"""eww_theme_set.py — settings > UI live theme controls (no file editing).

usage: eww_theme_set.sh accent <hex>   — set $on (+$accent_3 if present, +$on_hover darkened)
       eww_theme_set.sh bg <0-100>     — set $bg alpha percent, keep rgb
Patches the CURRENT theme's colors.scss, then `eww reload`.
"""
import re
import subprocess
import sys
from pathlib import Path


def darken(hexcolor: str, f: float = 0.72) -> str:
    h = hexcolor.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    r, g, b = (max(0, min(255, round(int(h[i:i + 2], 16) * f))) for i in (0, 2, 4))
    return f"#{r:02x}{g:02x}{b:02x}"


def parse_rgb(s: str):
    s = s.strip()
    m = re.match(r"rgba?\(([^)]+)\)", s)
    if m:
        parts = [p.strip() for p in m.group(1).split(",")]
        return int(parts[0]), int(parts[1]), int(parts[2])
    h = s.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def main() -> None:
    if len(sys.argv) < 3:
        print("usage: eww_theme_set.sh accent <hex> | bg <0-100>")
        sys.exit(1)
    mode, val = sys.argv[1], sys.argv[2]

    theme = Path.home().joinpath(".config/eww/themes/current_theme.txt").read_text().strip()
    colors = Path.home() / f"dotfiles/.config/eww/themes/{theme}/eww/scss/colors.scss"
    text = colors.read_text()

    if mode == "accent":
        if not re.match(r"#?[0-9a-fA-F]{3}([0-9a-fA-F]{3})?$", val):
            sys.exit(1)
        hexcolor = val if val.startswith("#") else f"#{val}"
        text, n = re.subn(r"(\$on:\s*)#[0-9a-fA-F]{3,6}", rf"\g<1>{hexcolor}", text, count=1)
        if re.search(r"\$accent_3:", text):
            text = re.sub(r"(\$accent_3:\s*)#[0-9a-fA-F]{3,6}", rf"\g<1>{hexcolor}", text, count=1)
        text = re.sub(r"(\$on_hover:\s*)#[0-9a-fA-F]{3,6}",
                      rf"\g<1>{darken(hexcolor)}", text, count=1)
    elif mode == "bg":
        try:
            alpha = max(20, min(100, int(val))) / 100
        except ValueError:
            sys.exit(1)
        m = re.search(r"(\$bg:\s*)([^;]+);", text)
        if not m:
            sys.exit(1)
        r, g, b = parse_rgb(m.group(2))
        text = text[: m.start(2)] + f"rgba({r}, {g}, {b}, {alpha})" + text[m.end(2):]
    else:
        print(f"unknown mode: {mode}")
        sys.exit(1)

    colors.write_text(text) 

if __name__ == "__main__":
    main()
