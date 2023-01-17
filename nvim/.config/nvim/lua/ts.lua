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
		gitmoji = {
			action = function(entry)
				local emoji = entry.value.value
				vim.ui.input({ prompt = "Enter commit message: " .. emoji .. " " }, function(msg)
					if not msg then
						return
					end
					-- Insert text instead of emoji in message
					local emoji_text = entry.value.text
					vim.cmd(':!git commit -m "' .. emoji_text .. " " .. msg .. '"')
				end)
			end,
		},
	},
})

telescope.load_extension("ui-select")
telescope.load_extension("refactoring")
telescope.load_extension("gitmoji")
telescope.load_extension("lazygit")
