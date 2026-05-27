hl.window_rule({
	name = "zathura-rules",
	match = { class = "^(org.pwmt.zathura)$" },
	workspace = 2,
	fullscreen = true,
})

hl.window_rule({
	name = "mpv-rules",
	match = { class = "^(mpv)$" },
	workspace = 9,
	fullscreen = true,
})

hl.workspace_rule({ workspace = "w[1-10]", animation = "slidefadevert" })
