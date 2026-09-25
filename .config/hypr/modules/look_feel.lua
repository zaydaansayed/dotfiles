-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/ for more info
hl.config({
    general = {
        gaps_in  = 5,
	gaps_out = 5,

        border_size = 2,

        col = {
            active_border   = { colors = {"rgb(E99AFF)", "rgb(549D9D)"}, angle = 0 },
            inactive_border = "rgb(090409)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 9,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 0.99,
        inactive_opacity = 0.99,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.config({
    misc = {
        animate_manual_resizes = true,
        animate_mouse_windowdragging = true,
    },
})

-- SMOOTH CLEAN (high-end, no bounce) curves, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("smooth", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.0} } })
hl.curve("ease",   { type = "bezier", points = { {0.23, 1},   {0.32, 1}  } })
hl.curve("quick",  { type = "bezier", points = { {0.15, 0},   {0.1, 1}   } })
hl.curve("liner",  { type = "bezier", points = { {0, 0},      {1, 1}     } })

hl.animation({ leaf = "windows",          enabled = true, speed = 6,  bezier = "smooth", style = "slide" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 6,  bezier = "smooth", style = "slide" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 6,  bezier = "ease",   style = "popin 80%" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 5,  bezier = "smooth", style = "slide" })
hl.animation({ leaf = "border",           enabled = true, speed = 10, bezier = "smooth" })
hl.animation({ leaf = "borderangle",      enabled = true, speed = 8,  bezier = "liner",  style = "loop" })
hl.animation({ leaf = "fade",             enabled = true, speed = 7,  bezier = "smooth" })
hl.animation({ leaf = "fadeIn",           enabled = true, speed = 7,  bezier = "smooth" })
hl.animation({ leaf = "fadeOut",          enabled = true, speed = 7,  bezier = "ease" })
hl.animation({ leaf = "layers",           enabled = true, speed = 5,  bezier = "smooth", style = "slidefade" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 5,  bezier = "smooth", style = "slidefade" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 5,  bezier = "ease",   style = "fade" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 5,  bezier = "smooth" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 5,  bezier = "ease" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 5,  bezier = "smooth", style = "slide" })
hl.animation({ leaf = "workspacesIn",     enabled = true, speed = 5,  bezier = "smooth", style = "slide" })
hl.animation({ leaf = "workspacesOut",    enabled = true, speed = 5,  bezier = "smooth", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 6,  bezier = "smooth", style = "slidevert" })
hl.animation({ leaf = "zoomFactor",       enabled = true, speed = 7,  bezier = "quick" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

-------------------------------------------------------------------------------- 
------------------------ MADE BY ZAYDAAN SAYED 2026 ----------------------------
--------------------------------------------------------------------------------
