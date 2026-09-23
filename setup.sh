#!/bin/bash
# setup.sh — set up this rice on a fresh Arch install.
# Usage: ./setup.sh [deps|link|theme|apps|all]
#   deps   install system packages (needs sudo via pacman/yay)
#   link   symlink dotfiles into ~/.config + install .desktop entries
#   theme  apply the night_sky theme (regenerates eww + hypr bits)
#   apps   refresh the eww app launcher index
#   all    everything (default)
set -u

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEP="${1:-all}"

PACMAN_PKGS=(
  hyprland hyprpaper hyprlock hypridle kitty mako wl-clipboard cliphist
  jq socat brightnessctl playerctl networkmanager bluez bluez-utils rfkill
  udiskie kdeconnect fastfetch firefox ttf-jetbrains-mono noto-fonts-emoji
  libnotify grim slurp hyprshot brightnessctl pavucontrol
  xdg-desktop-portal-hyprland
)
AUR_PKGS=(eww otf-monocraft pixora-icons-git obs-studio)

have() { command -v "$1" >/dev/null 2>&1; }

step_deps() {
  echo "==> [deps] installing repo packages (sudo password needed)"
  sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" || echo "!! some repo packages failed"
  if ! have yay; then
    echo "==> installing yay"
    sudo pacman -S --needed --noconfirm base-devel git || exit 1
    (cd /tmp && rm -rf yay && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm)
  fi
  echo "==> [deps] installing AUR packages"
  for p in "${AUR_PKGS[@]}"; do
    yay -S --needed --noconfirm "$p" || echo "!! $p failed (continuing)"
  done
  echo "==> enabling NetworkManager + bluetooth"
  sudo systemctl enable --now NetworkManager bluetooth 2>/dev/null || true
}

step_link() {
  echo "==> [link] symlinking dotfiles"
  mkdir -p "$HOME/.config" "$HOME/.local/share/applications" "$HOME/Pictures/Wallpapers"
  for d in "$DOTFILES"/.config/*/; do
    name=$(basename "$d")
    target="$HOME/.config/$name"
    if [[ -e "$target" && ! -L "$target" ]]; then
      echo "!! $target exists and is not a symlink — backing up to $target.bak"
      mv "$target" "$target.bak"
    fi
    ln -sfn "$d" "$target"
    echo "linked $target -> $d"
  done
  chmod +x "$DOTFILES"/.config/eww/scripts/*.sh "$DOTFILES"/.config/hypr/scripts/*.sh 2>/dev/null || true
  echo "==> installing .desktop entries"
  cp -f "$DOTFILES"/applications/*.desktop "$HOME/.local/share/applications/" 2>/dev/null || true
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
}

step_theme() {
  echo "==> [theme] applying night_sky"
  bash "$HOME/.config/eww/themes/night_sky/application.sh"
}

step_apps() {
  echo "==> [apps] refreshing launcher index"
  "$HOME/.config/eww/scripts/launcher.sh" >/dev/null 2>&1 || true
}

case "$STEP" in
  deps) step_deps ;;
  link) step_link ;;
  theme) step_theme ;;
  apps) step_apps ;;
  all) step_deps; step_link; step_theme; step_apps ;;
  *) echo "usage: $0 [deps|link|theme|apps|all]"; exit 1 ;;
esac

echo "==> done. Log out and pick the Hyprland session, or run: Hyprland"
