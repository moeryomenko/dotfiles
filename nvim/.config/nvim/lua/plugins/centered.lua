return {
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
}
