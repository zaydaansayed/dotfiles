--------------------------------
----------- WINDOWS ------------
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Add this to your layer rules section
hl.layer_rule({
    name = "eww-blur",
    match = { namespace = "^gtk-layer-shell$" },
    blur = true,
    ignore_alpha = 0.1
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Fixes xwayland bugs
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

-- Allows the about window to look good
hl.window_rule({
    name = "fastfetch-floating",
    match = { class = "fastfetch-term" },
    float = true,
    size = "600 400",
    center = true,
})

hl.window_rule({
    name = "tui_cal-floating",
    match = { class = "tui_calculator" },
    float = true,
    size = "400 700",
    center = true,
})

-------------------------------------------------------------------------------- 
------------------------ MADE BY ZAYDAAN SAYED 2026 ----------------------------
--------------------------------------------------------------------------------
