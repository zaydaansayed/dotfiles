#!/usr/bin/env bash
#
# setup.sh — cross-distro setup for zaydaansayed's Hyprland + eww rice.
#
# Usage:
#   ./setup.sh [deps|link|theme|apps|all] [options]
#
# Steps:
#   deps   install system packages (needs sudo)
#   link   stow dotfiles + install .desktop entries
#   theme  apply default theme (night_sky)
#   apps   install extras: eww (if needed), weather-cli, fonts,
#          cursor theme, icon theme
#   all    deps + apps + link + theme (default)
#
# Options:
#   -y, --yes        don't prompt for confirmation
#   --skip-deps      skip system packages (only with `all`)
#   --skip-apps      skip extras (only with `all`)
#   --no-theme       skip theme step (only with `all`)
#   --pm=<mgr>       force package manager: pacman|apt|dnf|zypper|apk|xbps|emerge|nix
#                    (useful for nix on non-NixOS distros: --pm=nix)
#   -h, --help       show this help
#
# Supported distros (best effort — unknown ones get a manual list):
#   Arch / EndeavourOS / Manjaro (pacman + AUR helper)
#   Debian / Ubuntu / Mint / Pop!_OS (apt)
#   Fedora / RHEL / CentOS Stream (dnf)
#   openSUSE Tumbleweed / Leap (zypper)
#   Alpine (apk), Void (xbps), Gentoo (emerge)
#   NixOS, or any distro with the nix package manager (nix)
#     NOTE (NixOS): `deps`/`apps` only install user tools into your nix
#     profile. A working Hyprland session still needs system config in
#     configuration.nix (programs.hyprland.enable, fonts, services) —
#     the script prints exactly what to add.
#
# Re-runnable: link backs up conflicts instead of deleting,
# .desktop files are copied (not moved), autostart is only
# written when missing.

set -euo pipefail

# ---------------------------------------------------------------- helpers ---

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ASSUME_YES=0
SKIP_DEPS=0
SKIP_APPS=0
SKIP_THEME=0
FORCE_PM=""

info()  { printf '\033[1;34m[setup]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[setup:warn]\033[0m %s\n' "$*" >&2; }
die()   { printf '\033[1;31m[setup:error]\033[0m %s\n' "$*" >&2; exit 1; }
have()  { command -v "$1" >/dev/null 2>&1; }

confirm() {
  if [ "$ASSUME_YES" -eq 1 ]; then return 0; fi
  printf '%s [y/N] ' "$1"
  read -r ans || return 1
  case "$ans" in [yY][eE][sS]|[yY]) return 0 ;; *) return 1 ;; esac
}

run_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif have sudo; then
    sudo "$@"
  else
    die "Need root (no sudo found). Re-run as root: $*"
  fi
}

# ------------------------------------------------- distro detection ---

# Sets: DISTRO_ID (lowercase ID), DISTRO_LIKE, PKG_MGR, IS_ARCH, IS_DEBIAN, ...
detect_distro() {
  DISTRO_ID="unknown"
  DISTRO_LIKE=""
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID="$(printf '%s' "${ID:-unknown}" | tr '[:upper:]' '[:lower:]')"
    DISTRO_LIKE="$(printf '%s' "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')"
  fi

  PKG_MGR=""
  case "$DISTRO_ID $DISTRO_LIKE" in
    *arch*|*endeavouros*|*manjaro*|*cachyos*|*garuda*) PKG_MGR="pacman" ;;
    *artix*)                                           PKG_MGR="pacman" ;;
    *nixos*)                                           PKG_MGR="nix" ;;
  esac
  if [ -z "$PKG_MGR" ]; then
    if have pacman; then PKG_MGR="pacman";
    elif have apt-get; then PKG_MGR="apt";
    elif have dnf; then PKG_MGR="dnf";
    elif have zypper; then PKG_MGR="zypper";
    elif have apk; then PKG_MGR="apk";
    elif have xbps-install; then PKG_MGR="xbps";
    elif have emerge; then PKG_MGR="emerge";
    elif have nix; then PKG_MGR="nix";
    else PKG_MGR="unknown";
    fi
  fi

  # --pm= override (e.g. nix on a non-NixOS distro).
  if [ -n "$FORCE_PM" ]; then
    case "$FORCE_PM" in
      pacman|apt|dnf|zypper|apk|xbps|emerge|nix|unknown) PKG_MGR="$FORCE_PM" ;;
      *) die "Unknown package manager: $FORCE_PM (try --help)" ;;
    esac
  fi

  info "Detected distro: $DISTRO_ID (like: ${DISTRO_LIKE:-none}), package manager: $PKG_MGR"
}

is_nixos() { [ "${DISTRO_ID:-unknown}" = "nixos" ]; }

# ------------------------------------------------- package lists ---

# Runtime deps common to every distro (names mapped per manager below).
install_deps() {
  detect_distro
  case "$PKG_MGR" in
    pacman) install_deps_pacman ;;
    apt)    install_deps_apt ;;
    dnf)    install_deps_dnf ;;
    zypper) install_deps_zypper ;;
    apk)    install_deps_apk ;;
    xbps)   install_deps_xbps ;;
    emerge) install_deps_gentoo ;;
    nix)    install_deps_nix ;;
    *)      install_deps_unknown ;;
  esac
  info "Dependency step done. Anything marked MISSING below has a fallback in './setup.sh apps'."
}

install_deps_pacman() {
  local pkgs=(
    # hyprland stack
    hyprland hyprpaper hypridle hyprlock
    # bar / widgets / notifications / terminal
    kitty mako fastfetch cava imv
    # clipboard / screenshots / media keys
    wl-clipboard cliphist grim slurp hyprshot
    playerctl brightnessctl pamixer
    networkmanager bluez bluez-utils upower
    # shell / tools
    fish neovim yazi stow git curl jq socat
    python python-pip udiskie tlp
    # audio
    pipewire pipewire-pulse wireplumber
    # fonts + gtk bits (eww build + tray)
    ttf-jetbrains-mono noto-fonts-emoji
    gtk-layer-shell libdbusmenu-glib libdbusmenu-gtk3
    # toolchain (eww fallback build)
    base-devel rust
    firefox
  )
  ensure_aur_helper
  info "Installing with pacman: ${pkgs[*]}"
  run_sudo pacman -S --needed --noconfirm "${pkgs[@]}" || {
    warn "pacman reported errors (some packages may not exist on this Arch derivative)."
    warn "Continuing — './setup.sh apps' covers eww/fonts fallbacks."
  }
  enable_services
}

install_deps_apt() {
  local pkgs=(
    hyprland hyprpaper hypridle hyprlock
    kitty mako fastfetch cava imv
    wl-clipboard grim slurp
    playerctl brightnessctl pamixer
    network-manager bluez upower
    fish neovim stow git curl jq socat
    python3 python3-pip udiskie tlp
    pipewire pipewire-pulse wireplumber
    fonts-jetbrains-mono fonts-noto-color-emoji
    libgtk-layer-shell0
    build-essential cargo rustc
    firefox
  )
  # yazi + cliphist + hyprshot only exist on newer Debian/Ubuntu — try, tolerate failure.
  local extra=(yazi cliphist hyprshot)
  info "Updating apt cache…"
  run_sudo apt-get update
  info "Installing with apt."
  if [ "$ASSUME_YES" -eq 1 ]; then
    run_sudo apt-get install -y "${pkgs[@]}" || warn "Some packages failed — continuing."
    run_sudo apt-get install -y "${extra[@]}" || warn "Optional packages (${extra[*]}) unavailable here — 'apps' step will use cargo fallbacks."
  else
    run_sudo apt-get install "${pkgs[@]}" || warn "Some packages failed — continuing."
    run_sudo apt-get install "${extra[@]}" || warn "Optional packages (${extra[*]}) unavailable here — 'apps' step will use cargo fallbacks."
  fi
  enable_services
}

install_deps_dnf() {
  local pkgs=(
    hyprland hyprpaper hypridle hyprlock
    kitty mako fastfetch cava imv
    wl-clipboard grim slurp
    playerctl brightnessctl pamixer
    NetworkManager bluez upower
    fish neovim yazi stow git curl jq socat
    python3 python3-pip udiskie tlp
    pipewire pipewire-pulse wireplumber
    jetbrains-mono-fonts google-noto-emoji-color-fonts
    gtk-layer-shell
    gcc gcc-c++ make rust cargo
    firefox
  )
  local opts=()
  if [ "$ASSUME_YES" -eq 1 ]; then opts=(-y); fi
  info "Installing with dnf (hyprshot/cliphist may be missing → covered by 'apps' fallbacks)."
  run_sudo dnf install "${opts[@]}" "${pkgs[@]}" || warn "dnf reported errors — continuing."
  # best-effort extras that live in RPM Fusion / COPR on some releases
  run_sudo dnf install "${opts[@]}" cliphist hyprshot 2>/dev/null \
    || warn "cliphist/hyprshot not in repos — grim+slurp already installed as fallback."
  enable_services
}

install_deps_zypper() {
  local pkgs=(
    hyprland hyprpaper hypridle hyprlock
    kitty mako fastfetch cava imv
    wl-clipboard grim slurp
    playerctl brightnessctl pamixer
    NetworkManager bluez upower
    fish neovim yazi stow git curl jq socat
    python3 python3-pip udiskie tlp
    pipewire pipewire-pulse wireplumber
    jetbrains-mono-fonts
    gtk-layer-shell
    gcc gcc-c++ make rust cargo
    firefox
  )
  if [ "$ASSUME_YES" -eq 1 ]; then
    run_sudo zypper --non-interactive install "${pkgs[@]}" || warn "zypper reported errors — continuing."
  else
    run_sudo zypper install "${pkgs[@]}" || warn "zypper reported errors — continuing."
  fi
  enable_services
}

install_deps_apk() {
  local pkgs=(
    hyprland hyprpaper hypridle hyprlock
    kitty mako fastfetch cava imv
    wl-clipboard grim slurp
    playerctl brightnessctl pamixer
    networkmanager bluez upower
    fish neovim yazi stow git curl jq socat
    python3 py3-pip udiskie tlp
    pipewire pipewire-pulse wireplumber
    font-jetbrains-mono font-noto-emoji
    gtk-layer-shell
    build-base cargo rust
    firefox
  )
  if [ "$ASSUME_YES" -eq 1 ]; then
    run_sudo apk add --no-cache "${pkgs[@]}" || warn "apk reported errors — continuing."
  else
    run_sudo apk add "${pkgs[@]}" || warn "apk reported errors — continuing."
  fi
  enable_services
}

install_deps_xbps() {
  local pkgs=(
    hyprland hyprpaper hypridle hyprlock
    kitty mako fastfetch cava imv
    wl-clipboard grim slurp
    playerctl brightnessctl pamixer
    NetworkManager bluez upower
    fish neovim yazi stow git curl jq socat
    python3 python3-pip udiskie tlp
    pipewire wireplumber
    jetbrains-mono-fonts
    gtk-layer-shell
    base-devel rust cargo
    firefox
  )
  if [ "$ASSUME_YES" -eq 1 ]; then
    run_sudo xbps-install -Sy "${pkgs[@]}" || warn "xbps reported errors — continuing."
  else
    run_sudo xbps-install -S "${pkgs[@]}" || warn "xbps reported errors — continuing."
  fi
  enable_services
}

install_deps_gentoo() {
  warn "Gentoo detected — emerging everything can take a long time."
  confirm "Emerging gui-wm/hyprland + tools. Continue?" || return 0
  run_sudo emerge --ask=n \
    gui-wm/hyprland gui-apps/hyprpaper gui-apps/hypridle gui-apps/hyprlock \
    x11-terms/kitty x11-misc/mako app-misc/fastfetch media-sound/cava \
    media-gfx/imv gui-apps/wl-clipboard gui-apps/grim gui-apps/slurp \
    media-sound/playerctl app-misc/brightnessctl media-sound/pamixer \
    net-misc/networkmanager sys-bluez/bluez sys-power/upower \
    app-shells/fish app-editors/neovim app-misc/yazi \
    app-admin/stow dev-vcs/git net-misc/curl app-misc/jq net-misc/socat \
    dev-lang/python sys-power/tlp media-fonts/jetbrains-mono \
    dev-lang/rust www-client/firefox || warn "emerge reported errors — continuing."
  enable_services
}

install_deps_unknown() {
  warn "No supported package manager found ($PKG_MGR)."
  cat <<'EOF'
Install these manually with your distro's package manager, then re-run ./setup.sh link:
  hyprland hyprpaper hypridle hyprlock kitty mako fish neovim yazi
  fastfetch cava imv wl-clipboard cliphist grim slurp playerctl
  brightnessctl networkmanager bluez upower udiskie socat jq stow
  git curl python3 pipewire wireplumber tlp firefox
  JetBrains Mono font, rust/cargo (for building eww)
EOF
}

# ------------------------------------------------- nix helpers ---

nix_supports_flakes() {
  # True if `nix profile` (flakes new CLI) is usable.
  have nix || return 1
  nix profile --help >/dev/null 2>&1 || return 1
  if nix show-config 2>/dev/null | grep -Eq "experimental-features.*(flake|nix-command)"; then
    return 0
  fi
  nix --extra-experimental-features 'nix-command flakes' eval --expr '1' >/dev/null 2>&1
}

nix_install() {
  # nix_install <attr>... — install nixpkgs attrs into the user profile.
  # Prefers `nix profile` (flakes), falls back to classic `nix-env -iA`.
  # Never needs sudo.
  if nix_supports_flakes; then
    info "Installing via nix profile: $*"
    # shellcheck disable=SC2068
    nix profile install ${@/#/nixpkgs#} && return 0
    warn "'nix profile install' failed — is your nixpkgs flake registry/channel up to date? (try: nix-channel --update, or enable flakes)"
    return 1
  fi
  local channel=nixpkgs
  # NixOS channels expose `nixos.<attr>`; standalone nixpkgs channels use `nixpkgs.<attr>`.
  if nix-env -qaP -A nixos.hello >/dev/null 2>&1; then
    channel=nixos
  elif nix-env -qaP -A nixpkgs.hello >/dev/null 2>&1; then
    channel=nixpkgs
  else
    warn "No nix channel found. Add one first, e.g.: nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs && nix-channel --update"
    return 1
  fi
  info "Installing via nix-env -iA $channel.*: $*"
  # shellcheck disable=SC2068
  nix-env -iA ${@/#/$channel.}
}

install_deps_nix() {
  have nix || die "nix not found. Install it first: https://nixos.org/download (Determinate Systems installer is the easy path), then re-run './setup.sh deps'."
  local pkgs=(
    # hyprland stack
    hyprland hyprpaper hypridle hyprlock
    # bar / widgets / notifications / terminal
    kitty mako fastfetch cava imv
    # clipboard / screenshots / media keys
    wl-clipboard cliphist grim slurp hyprshot
    playerctl brightnessctl pamixer
    networkmanager bluez upower
    # shell / tools
    fish neovim yazi stow git curl jq socat
    python3 udiskie tlp
    # audio
    pipewire wireplumber
    # fonts + eww + toolchain
    jetbrains-mono noto-fonts-emoji
    eww rustc cargo
    firefox
  )
  nix_install "${pkgs[@]}" || {
    warn "Some nix packages failed (a name may differ on your channel — run 'nix search nixpkgs <name>' to check)."
    warn "Continuing — './setup.sh apps' covers eww/fonts fallbacks."
  }
  if is_nixos; then
    cat <<'EOF'
[setup] NixOS note: profile installs above only provide user tools.
[setup] A working Hyprland session needs system config. Add to configuration.nix:
[setup]
[setup]   programs.hyprland.enable = true;
[setup]   fonts.packages = with pkgs; [ jetbrains-mono noto-fonts-emoji ];
[setup]   networking.networkmanager.enable = true;
[setup]   hardware.bluetooth.enable = true;
[setup]   services.upower.enable = true;
[setup]   services.tlp.enable = true;   # or powerManagement.powertop, not both
[setup]   security.polkit.enable = true;
[setup]   # audio:
[setup]   services.pipewire = { enable = true; pulse.enable = true; };
[setup]
[setup] Then: sudo nixos-rebuild switch
EOF
  else
    enable_services
  fi
}

# ------------------------------------------------- arch helpers ---

ensure_aur_helper() {
  if have yay || have paru; then return 0; fi
  warn "No AUR helper (yay/paru) found — needed for AUR extras."
  confirm "Install yay now?" || { warn "Skipping AUR helper; AUR extras will be skipped."; return 0; }
  have git || run_sudo pacman -S --needed --noconfirm git base-devel
  local tmp
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmp/yay"
  (cd "$tmp/yay" && makepkg -si --noconfirm)
  rm -rf "$tmp"
}

aur_install() {
  # $1.. = AUR package names. Uses yay or paru, skips if neither exists.
  if have yay; then yay -S --needed --noconfirm "$@"
  elif have paru; then paru -S --needed --noconfirm "$@"
  else warn "Skipping AUR packages ($*): install yay/paru first."; return 1
  fi
}

enable_services() {
  # NetworkManager + bluetooth where systemd exists; harmless otherwise.
  # On NixOS services are declarative — systemctl enable would be wrong.
  if is_nixos; then
    warn "NixOS: enable services in configuration.nix instead (see note in 'deps' step) — skipping systemctl."
    return 0
  fi
  if have systemctl; then
    run_sudo systemctl enable --now NetworkManager 2>/dev/null || true
    run_sudo systemctl enable --now bluetooth 2>/dev/null || true
  fi
}

# ------------------------------------------------- apps / extras ---

install_apps() {
  detect_distro
  info "Installing extras (eww, weather-cli, fonts, cursor, icons)…"

  # --- eww: prefer repo/AUR, else build from source ---
  if have eww; then
    info "eww already installed: $(command -v eww)"
  else
    info "eww not found — trying packaged install first."
    case "$PKG_MGR" in
      pacman) aur_install eww || build_eww_from_source ;;
      apt)    run_sudo apt-get install -y eww 2>/dev/null || build_eww_from_source ;;
      dnf)    run_sudo dnf install -y eww 2>/dev/null || build_eww_from_source ;;
      zypper) run_sudo zypper --non-interactive install eww 2>/dev/null || build_eww_from_source ;;
      nix)    nix_install eww || build_eww_from_source ;;
      *)      build_eww_from_source ;;
    esac
  fi

  # --- weather-cli: AUR on Arch, cargo elsewhere ---
  if have weather-cli || have weather; then
    info "weather-cli already installed."
  else
    case "$PKG_MGR" in
      pacman) aur_install weather-cli || cargo_install weather-cli ;;
      *)      cargo_install weather-cli ;;
    esac
  fi

  # --- yazi / cliphist fallbacks (cargo) when the repo lacked them ---
  if ! have yazi; then
    warn "yazi missing — trying cargo."
    cargo_install yazi-fm
  fi
  if ! have cliphist; then
    warn "cliphist missing — trying cargo (clipboard history falls back to wl-clipboard without it)."
    cargo_install cliphist || true
  fi
  if ! have hyprshot && ! have grim; then
    warn "No screenshot tool (hyprshot/grim) found — install grim+slurp from your package manager."
  fi

  install_fonts
  install_cursor_theme
  install_icon_theme
}

cargo_install() {
  if ! have cargo; then
    warn "cargo not found — cannot 'cargo install $*'. Install rust first (./setup.sh deps)."
    return 1
  fi
  # shellcheck disable=SC2068
  cargo install --locked $@ || cargo install $@ || return 1
  case ":$HOME/.cargo/bin:$PATH:" in
    *":$HOME/.cargo/bin:"*) ;;
    *) warn "cargo installed to ~/.cargo/bin which is not on PATH. Add: export PATH=\"\$HOME/.cargo/bin:\$PATH\"" ;;
  esac
}

build_eww_from_source() {
  info "Building eww from source (elkowar/eww, wayland-only)…"
  have cargo || die "cargo is required to build eww. Run './setup.sh deps' first."
  have git || die "git is required to build eww. Run './setup.sh deps' first."
  local src="$HOME/eww"
  if [ ! -d "$src/.git" ]; then
    git clone https://github.com/elkowar/eww "$src"
  fi
  (
    cd "$src"
    git pull --ff-only || true
    cargo build --release --no-default-features --features=wayland
  )
  run_sudo install -m 0755 "$src/target/release/eww" /usr/local/bin/eww
  info "eww installed to /usr/local/bin/eww"
}

install_fonts() {
  local fontdir="$HOME/.local/share/fonts"
  mkdir -p "$fontdir"

  # JetBrains Mono — skip if fc-list already sees it.
  if have fc-list && fc-list 2>/dev/null | grep -qi "jetbrains"; then
    info "JetBrains Mono already installed."
  else
    info "Installing JetBrains Mono to $fontdir…"
    local ver="v3.3.1"
    local zip="$fontdir/JetBrainsMono.zip"
    if have curl; then
      curl -fL "https://github.com/JetBrains/JetBrainsMono/releases/download/${ver}/JetBrainsMono-${ver}.zip" -o "$zip" \
        && (cd "$fontdir" && unzip -o -q "$zip" 'fonts/ttf/*.ttf' 2>/dev/null || unzip -o -q "$zip") \
        && rm -f "$zip" \
        || warn "JetBrains Mono download failed — install fonts-jetbrains-mono / ttf-jetbrains-mono manually."
    else
      warn "curl missing — cannot download JetBrains Mono."
    fi
  fi

  # Monocraft (used by gsettings theme step) — Arch has otf-monocraft in AUR.
  if have fc-list && fc-list 2>/dev/null | grep -qi "monocraft"; then
    info "Monocraft already installed."
  else
    if [ "$PKG_MGR" = "pacman" ]; then
      aur_install otf-monocraft || download_monocraft
    else
      download_monocraft
    fi
  fi

  if have fc-cache; then fc-cache -f "$fontdir" >/dev/null 2>&1 || true; fi
}

download_monocraft() {
  info "Downloading Monocraft font…"
  have curl || { warn "curl missing — skipping Monocraft."; return 0; }
  local out="$HOME/.local/share/fonts/Monocraft.otf"
  curl -fL "https://github.com/IdreesInc/Monocraft/releases/latest/download/Monocraft.otf" -o "$out" \
    || warn "Monocraft download failed — cosmetic only, continuing."
}

install_cursor_theme() {
  if [ -d "$HOME/.local/share/icons/Bibata-Modern-Classic" ] || [ -d /usr/share/icons/Bibata-Modern-Classic ]; then
    info "Bibata cursor theme already installed."
    return 0
  fi
  if [ "$PKG_MGR" = "pacman" ]; then
    aur_install bibata-cursor-theme && return 0 || true
  fi
  info "Installing Bibata-Modern-Classic cursors…"
  have curl || { warn "curl missing — skipping cursor theme."; return 0; }
  local tmp
  tmp="$(mktemp -d)"
  if curl -fL "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata.tar.gz" -o "$tmp/Bibata.tar.gz"; then
    mkdir -p "$HOME/.local/share/icons"
    tar -xzf "$tmp/Bibata.tar.gz" -C "$HOME/.local/share/icons"
  else
    warn "Bibata download failed — cosmetic only, continuing."
  fi
  rm -rf "$tmp"
}

install_icon_theme() {
  if [ -d "$HOME/.local/share/icons/Pixora" ] || [ -d /usr/share/icons/Pixora ]; then
    info "Pixora icons already installed."
    return 0
  fi
  if [ "$PKG_MGR" = "pacman" ]; then
    aur_install pixora-icons-git && return 0 || true
  fi
  info "Installing Pixora icon theme…"
  have git || { warn "git missing — skipping Pixora icons."; return 0; }
  local tmp
  tmp="$(mktemp -d)"
  if git clone --depth 1 https://github.com/ljmillbone/Pixora "$tmp/Pixora"; then
    mkdir -p "$HOME/.local/share/icons"
    cp -r "$tmp/Pixora/Pixora" "$HOME/.local/share/icons/" 2>/dev/null \
      || cp -r "$tmp/Pixora" "$HOME/.local/share/icons/Pixora"
  else
    warn "Pixora clone failed — cosmetic only, continuing."
  fi
  rm -rf "$tmp"
}

# ------------------------------------------------- link ---

is_stow_managed() {
  # True if $1 is a symlink, or a dir containing symlinks into DOTFILES_DIR
  # (i.e. stow already manages it — don't move it aside).
  local p="$1"
  [ -L "$p" ] && return 0
  if [ -d "$p" ]; then
    if find "$p" -maxdepth 2 -lname "$DOTFILES_DIR/*" 2>/dev/null | grep -q .; then
      return 0
    fi
  fi
  return 1
}

backup_if_exists() {
  # backup_if_exists <path> — moves existing non-symlink aside with timestamp.
  # Never touches anything that resolves inside DOTFILES_DIR: when stow
  # "folds" (e.g. ~/.config -> dotfiles/.config), $HOME paths can resolve
  # into the repo itself, and moving them would eat the repo.
  local p="$1" real
  real="$(readlink -m "$p")"
  case "$real" in
    "$DOTFILES_DIR"/*)
      info "$p is already stowed — leaving it alone."
      return 0
      ;;
  esac
  if is_stow_managed "$p"; then
    info "$p is already stowed — leaving it alone."
    return 0
  fi
  if [ -e "$p" ]; then
    local bak
    bak="${p}.bak.$(date +%Y%m%d%H%M%S)"
    warn "Backing up $p → $bak"
    mv "$p" "$bak"
  fi
}

link_dotfiles() {
  have stow || die "GNU stow is required. Run './setup.sh deps' first."
  cd "$DOTFILES_DIR"

  # stow would choke on a real ~/.config/hypr dir — back it up instead of rm -rf.
  backup_if_exists "$HOME/.config/hypr"

  info "Stowing dotfiles from $DOTFILES_DIR…"
  # --restow so re-runs converge; conflicts back up one by one via stow's error message.
  if ! stow --restow --target="$HOME" .; then
    warn "stow reported a conflict — backing up blockers and retrying once."
    # Find files stow complains about is fragile; back up the usual suspects.
    for d in .config/fish .config/kitty .config/nvim .config/yazi .config/cava .config/fastfetch .config/mako .config/imv .config/eww; do
      backup_if_exists "$HOME/$d"
    done
    stow --restow --target="$HOME" .
  fi

  # .desktop entries: COPY (old script used mv, which broke the repo on re-run).
  mkdir -p "$HOME/.local/share/applications"
  if [ -d "$DOTFILES_DIR/applications" ]; then
    for f in "$DOTFILES_DIR"/applications/*.desktop; do
      [ -e "$f" ] || continue
      info "Installing $(basename "$f") → ~/.local/share/applications/"
      install -m 0644 "$f" "$HOME/.local/share/applications/$(basename "$f")"
    done
  else
    warn "No applications/ directory in $DOTFILES_DIR — skipping .desktop install."
  fi
}

# ------------------------------------------------- theme ---

apply_theme() {
  local app="$HOME/.config/eww/themes/night_sky/application.sh"
  # After stow, the theme script may live at either location — prefer the stowed one.
  if [ ! -x "$app" ] && [ -x "$DOTFILES_DIR/.config/eww/themes/night_sky/application.sh" ]; then
    app="$DOTFILES_DIR/.config/eww/themes/night_sky/application.sh"
  fi
  if [ ! -x "$app" ]; then
    warn "Theme script not found ($app). Did './setup.sh link' run?"
    return 1
  fi
  info "Applying night_sky theme…"
  bash "$app" || warn "Theme script exited non-zero — continuing."
  write_autostart
}

write_autostart() {
  local dest="$HOME/.config/hypr/modules/autostart.lua"
  if [ -f "$dest" ]; then
    info "autostart.lua already exists — leaving it alone (delete it to regenerate)."
    return 0
  fi
  info "Writing default $dest"
  mkdir -p "$(dirname "$dest")"
  cat > "$dest" <<'EOF'
hl.on("hyprland.start", function ()
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
  hl.exec_cmd("wl-paste --watch cliphist store")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("mako")
  hl.exec_cmd("~/dotfiles/.config/eww/scripts/notification_popup.sh")
  hl.exec_cmd("eww daemon")
  hl.exec_cmd("eww open --no-daemonize setup")
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd("udiskie --tray")
end)
EOF
}

# ------------------------------------------------- usage ---

usage() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
  echo "Examples:"
  echo "  ./setup.sh all           # new machine (default)"
  echo "  ./setup.sh deps          # packages only (needs sudo)"
  echo "  ./setup.sh link          # stow + desktop entries"
  echo "  ./setup.sh theme         # apply night_sky theme"
  echo "  ./setup.sh apps          # eww, weather-cli, fonts, cursors, icons"
}

# ------------------------------------------------- main ---

main() {
  local cmd="all"
  while [ $# -gt 0 ]; do
    case "$1" in
      deps|link|theme|apps|all) cmd="$1"; shift ;;
      -y|--yes|--noconfirm) ASSUME_YES=1; shift ;;
      --pm=*) FORCE_PM="${1#--pm=}"; shift ;;
      --skip-deps) SKIP_DEPS=1; shift ;;
      --skip-apps) SKIP_APPS=1; shift ;;
      --no-theme) SKIP_THEME=1; shift ;;
      -h|--help|help) usage; exit 0 ;;
      *) die "Unknown argument: $1 (try --help)" ;;
    esac
  done

  case "$cmd" in
    deps)  install_deps ;;
    link)  link_dotfiles ;;
    theme) apply_theme ;;
    apps)  install_apps ;;
    all)
      if [ "$SKIP_DEPS" -eq 0 ]; then install_deps; else info "Skipping deps (--skip-deps)."; fi
      if [ "$SKIP_APPS" -eq 0 ]; then install_apps; else info "Skipping apps (--skip-apps)."; fi
      link_dotfiles
      if [ "$SKIP_THEME" -eq 0 ]; then apply_theme; else info "Skipping theme (--no-theme)."; fi
      cat <<'EOF'

#############################################
## Setup complete!                         ##
## Log out and pick the Hyprland session.  ##
## Or: eww open --no-daemonize setup       ##
#############################################
EOF
      ;;
  esac
}

main "$@"
