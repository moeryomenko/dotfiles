local status_ok, catppuccin = pcall(require, "catppuccin")
if not status_ok then
	return
end

catppuccin.setup({
	flavor = "macchiato",
	background = {
		light = "latte",
		dark = "macchiato",
	},
})

catppuccin.load()
