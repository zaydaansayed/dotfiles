#!/bin/bash
# emoji.sh — offline emoji picker backend (no network, no extra deps).
#   emoji.sh list        print JSON array [{"char":..., "name":...}] for eww
#   emoji.sh pick <char> copy <char> to clipboard, close picker, type it via wtype
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

do_list() {
  python3 - << 'EOF'
emojis = """😀 grinning face
😁 beaming face
😂 laughing tears
🤣 rolling laughing
😊 smiling blush
😍 heart eyes
😘 kiss
😎 sunglasses
🤔 thinking
😴 sleeping
😷 mask
🤯 exploding head
🥳 partying
😭 sobbing
😡 angry rage
👍 thumbs up
👎 thumbs down
👏 clapping
🙏 praying thanks
👋 waving hand
✌ victory hand
🤞 fingers crossed
✊ fist bump
👊 oncoming fist
🫶 heart hands
❤ red heart
💔 broken heart
💯 hundred points
✨ sparkles
🔥 fire
🎉 party popper
🎂 birthday cake
⚽ soccer ball
🎮 video game
🎧 headphones
🎵 music note
📷 camera
💡 light bulb
📚 books
💻 laptop
⌨ keyboard
🖨 printer
📱 phone
🔋 battery
🔌 plug
💾 floppy disk
📁 folder
📄 document
✂ scissors
📌 pushpin
📎 paperclip
🔑 key
🔒 locked
🔓 unlocked
⛔ no entry
✅ check mark
❌ cross mark
⚠ warning
ℹ info
❓ question mark
❗ exclamation
➡ right arrow
⬅ left arrow
⬆ up arrow
⬇ down arrow
🔄 refresh reload
⭐ star
🌙 moon
☀ sun
⛅ partly cloudy
🌧 rain cloud
❄ snowflake
🌈 rainbow
🌊 ocean wave
🌳 tree
🌸 cherry blossom
🌹 rose
🐱 cat face
🐶 dog face
🦊 fox
🐼 panda
🦁 lion
🐸 frog
🐵 monkey
🦄 unicorn
🐝 bee
🦋 butterfly
🍎 apple
🍕 pizza slice
🍔 hamburger
🍩 doughnut
☕ coffee
🍺 beer mug
🚗 car
✈ airplane
🚲 bicycle
🚀 rocket
⚓ anchor
🏠 house home
💼 briefcase work
🎓 graduation cap
💰 money bag
🛒 shopping cart
📈 chart growth
🧠 brain
👁 eye
💪 flexed biceps
🦷 tooth
🩷 pink heart
💜 purple heart
💙 blue heart
💚 green heart
🖤 black heart
🤍 white heart
🥀 wilted flower
🍀 four leaf clover""".strip().split("\n")
import json
print(json.dumps([{"char": l.split(" ", 1)[0], "name": l.split(" ", 1)[1]} for l in emojis]))
EOF
}

do_pick() {
  local char="${1:-}"
  [[ -z "$char" ]] && exit 1
  printf '%s' "$char" | wl-copy 2>/dev/null || true
  command -v eww >/dev/null 2>&1 && {
    eww close emoji 2>/dev/null || true
    eww update emoji_query="" 2>/dev/null || true
    hyprctl dispatch 'hl.dsp.submap ("reset")' 2>/dev/null || true
  }
  # Let focus return to the previous window, then type the emoji.
  sleep 0.25
  wtype "$char" 2>/dev/null || true
}

case "${1:-list}" in
  list) do_list ;;
  pick) shift; do_pick "${1:-}" ;;
  *) echo "usage: emoji.sh [list|pick <char>]" >&2; exit 1 ;;
esac
