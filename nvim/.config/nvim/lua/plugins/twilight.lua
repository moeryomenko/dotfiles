return {
	"folke/twilight.nvim",
	{
		"folke/zen-mode.nvim",
		lazy = false,
		cmd = "ZenMode",
		opts = {
			plugins = {
				gitsigns = true,
				tmux = true,
			},
		},
		keys = { { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" } },
	},
	{
		"arnamak/stay-centered.nvim",
		lazy = false,
		config = function()
			vim.keymap.set(
				{ "n", "v" },
				"<leader>st",
				require("stay-centered").toggle,
				{ desc = "Toggle stay-centered.nvim" }
			)
		end,
	},
}
