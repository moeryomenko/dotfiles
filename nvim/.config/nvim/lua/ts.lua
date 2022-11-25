-- This is your opts table
local telescope = require("telescope")
telescope.setup({
	playground = { enable = true },
	query_linter = {
		enable = true,
		use_virtual_text = true,
		lint_events = { "BufWrite", "CursorHold" },
	},
	ensure_installed = "all",
	highlight = {
		enable = true,
	},
	extensions = {
		["ui-select"] = {
			require("telescope.themes").get_dropdown({}),
		},
	},
})

telescope.load_extension("ui-select")
telescope.load_extension("refactoring")
