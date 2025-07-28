return {
	"https://gitlab.com/itaranto/plantuml.nvim",
	dependencies = {
		"aklt/plantuml-syntax",
	},
	version = "*",
	config = function()
		require("plantuml").setup({
			renderer = {
				type = "imv",
				options = {
					dark_mode = true,
					format = "svg",
				},
			},
			render_on_write = true,
		})
	end,
}
