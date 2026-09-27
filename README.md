# zaydaansayed's rice

Hyprland + eww desktop rice with two themes (`night_sky`, `default_dark`),
a spotlight launcher, desktop widgets, and a one-command setup script(for arch only).

![desktop preview](preview.png)

## Highlights

- **Bar + dock** (eww) — workspaces (dynamic buttons past 5), player, clock,
  battery/network/Bluetooth, quick settings, OBS recording indicator
- **Spotlight launcher** (`SUPER+SPACE`) — apps (most-used first), file search,
  web-search fallback, per-app web lookup, pin to dock + menu
- **Desktop widgets** — clock, system monitor, now-playing (positions editable
  in `eww/yuck/widgets.yuck`)
- **Settings window** — Wi-Fi, Bluetooth, DNS, audio, themes, plus a System page
  (brightness, awake mode, wallpaper cycler)
- **Main menu** — pinned apps shared with the dock (pin/unpin live)
- **Keybinds window** — via the Rice Keybinds app entry
- **Emoji picker** (`SUPER+.`) — offline, copies + types your pick
- **Awake mode** (`SUPER+I`) — toggles hypridle auto dim/lock with restart
- **Setup window + script** for new machines

## Install on arch

```bash
git clone zaydaansayed/dotfiles
~/dotfiles/setup_arch.sh
```

Then log out and pick the **Hyprland** session.

## Install on non-arch

```bash
git clone zaydaansayed/dotfiles
# install dependencies from dependencies.txt
~/dotfiles/setup_unsupported.sh
```

Then log out and pick the **Hyprland** session.

## Keybinds

| Bind | Action |
| ---- | ------ |
| SUPER+A | terminal (kitty) |
| SUPER+S | close window |
| SUPER+M | shutdown menu |
| SUPER+L | lock |
| SUPER+I | awake mode (no auto dim/lock) |
| SUPER+F | float toggle |
| SUPER+P / D | pseudotile / togglesplit |
| SUPER+SPACE | spotlight launcher |
| SUPER+V | clipboard history |
| SUPER+. | emoji picker |
| SUPER+1..0 | workspaces (SHIFT moves window) |
| SUPER+C | scratchpad |
| 3-finger horizontal | switch workspace |

Full list lives in the Rice Keybinds app and `.config/hypr/modules/input_keybinds.lua`.

## Layout

```text
.config/
  hypr/              Hyprland Lua config (hyprland.lua + modules/)
  eww/               widgets + scripts (yuck/, scss/, scripts/)
  eww/themes/        night_sky + default_dark (application.sh applies a theme)
applications/        .desktop entries (installed by setup.sh link)
setup_arch.sh        new-machine setup (arch only)
setup_unsupported.sh new-machine setup (non-arch)
dependencies.txt     dependencies for non-arch users
icon/                nvim icons cause i hate the default ones
preview.png          screenshot for posts like this one
support.md           contact + issue links
```

Theme files are generated — `application.sh` rewrites `eww/eww.yuck` and
`eww/eww.scss`, so edit the theme sources, not the generated files.
Shared windows (launcher, emoji, keybinds, setup, widgets) live in
`eww/yuck/` + `eww/scss/` so both themes get them automatically.

## Support

See [SUPPORT.md](support.md). Issues welcome.
