return {
	"NeogitOrg/neogit",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"sindrets/diffview.nvim",
		"nvim-telescope/telescope.nvim",
		"ibhagwan/fzf-lua",
	},
	event = "VeryLazy",
	config = function()
		local neogit = require("neogit")
		neogit.setup({
			disable_commit_confirmation = true,
			disable_insert_on_commit = false,
			integrations = { diffview = true },
			auto_refresh = false,
			console_timeout = 5000,
			auto_show_console = false,
			sections = {
				stashes = {
					folded = false,
				},
				recent = { folded = false },
			},
		})

		vim.api.nvim_set_keymap("n", "[_Git]<Space>", "<Cmd>Neogit<CR>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", "[_Git]s", "<Cmd>Neogit<CR>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", "[_Git]S", "<Cmd>Neogit<CR>", { noremap = true, silent = true })
	end,
}
