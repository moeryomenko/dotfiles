-- This is your opts table
require("nvim-dap-repl-highlights").setup()
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
	pickers = {
		colorscheme = {
			enable_preview = true,
		},
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
		advanced_git_search = {
			diff_plugin = "fugitive",
			-- customize git in previewer
			git_flags = { "-c", "delta.side-by-side=false" },
			git_diff_flags = {},
			show_builtin_git_pickers = false,
		},
	},
})

require("telescope-tabs").setup()
require("bookmarks").setup()
telescope.load_extension("ui-select")
telescope.load_extension("refactoring")
telescope.load_extension("advanced_git_search")
telescope.load_extension("lazygit")
telescope.load_extension("bookmarks")
