local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
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

hl.layer_rule({
    name  = "blur-powermenu",
    match = { namespace = "^prometheus-powermenu$" },

    blur = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
	name = "music-bind",
	match = { class = "Spotify" },
	workspace = "1"
})

hl.window_rule({
	name = "browser-bind",
	match = { class = browser },
	workspace = "2"
})

hl.window_rule({
	name = "notes-bind",
	match = { class = notes },
	workspace = "4"
})
