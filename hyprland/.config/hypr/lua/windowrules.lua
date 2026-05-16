hl.window_rule({
    name = "zathura-rules",
    match = { class = "^(org.pwmt.zathura)$" },
    workspace = 5,
    fullscreen = true,
})

hl.window_rule({
    name = "telegram-workspace",
    match = { class = "^(org.telegram.desktop)$" },
    workspace = 4,
    no_screen_share = true,
})
