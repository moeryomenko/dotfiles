local status_ok, tokyonight = pcall(require, "tokyonight")
if not status_ok then
	return
end

tokyonight.setup({
	style = "storm",
	transparent = false,
	terminal_colors = true,
	styles = {
		comments = { italic = true },
		keywords = { italic = true, bold = true },
		functions = {},
		variables = {},
		sidebars = "dark",
		floats = "dark",
	},
	sidebars = { "qf", "help" },
	hide_inactive_statusline = false,
	dim_inactive = false,
	lualine_bold = false,
})

tokyonight.load()
