---------------
---- INPUT ----
---------------

--- Allows you to use hyprland properly

hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },
    }
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

hl.device({
    name = "synaptics-tm3471-020",
    sensitivity = 0,
    tap_to_click = true,
})

---------------------
---- KEYBINDINGS ----
---------------------

-- Use the premade keybinds as examples for any future keybinds use wev to find key names

local mainMod = "SUPER"

-- General buttons
hl.bind(mainMod .. " + A",      hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + S",      hl.dsp.window.close())
hl.bind(mainMod .. " + M",      hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + F",      hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT  + SPACE",         hl.dsp.exec_cmd("fuzzel"))
hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo())
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd("$HOME/dotfiles/.config/eww/scripts/main_toggle.sh"))
hl.bind(mainMod .. " + D",      hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + V",      hl.dsp.exec_cmd("~/dotfiles/.config/fuzzel/clipboard.sh"))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("bemoji"))
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("hyprlock"))

-- Window control
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + C",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Function Buttons
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ && ~/.config/eww/scripts/volume_buttons.sh"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && ~/.config/eww/scripts/volume_buttons.sh"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && ~/.config/eww/scripts/volume_buttons.sh"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+ && ~/.config/eww/scripts/brightness_buttons.sh"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%- && ~/.config/eww/scripts/brightness_buttons.sh"),                  { locked = true, repeating = true })
hl.bind("Print",                hl.dsp.exec_cmd("eww open --toggle screenprint"),       { locked = true, repeating = true })
hl.bind("XF86Favorites",        hl.dsp.exec_cmd("wtype zaydaansayed@icloud.com"),  { locked = true, repeating = true })

-- Music buttons
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-------------------------------------------------------------------------------- 
------------------------ MADE BY ZAYDAAN SAYED 2026 ----------------------------
--------------------------------------------------------------------------------
