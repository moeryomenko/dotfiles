hl.window_rule({
	name = "zathura-rules",
	match = { class = "^(org.pwmt.zathura)$" },
	workspace = 2,
})

hl.window_rule({
	name = "telegram",
	match = { class = "^(org.telegram.desktop)$" },
	scrolling_width = 0.25,
})

hl.workspace_rule({ workspace = "w[1-10]", animation = "slidevert" })
