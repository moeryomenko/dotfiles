return {
	"renerocksai/telekasten.nvim",
	lazy = false,
	dependencies = { "nvim-telescope/telescope.nvim" },
	config = function()
		require("telekasten").setup({
			home = vim.fn.expand("~/notes"),
			daily_note_filename = "%Y-%m-%d.md",
		})
	end,
}
