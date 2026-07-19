return {
	"hedyhli/outline.nvim",
	lazy = false,
	cmd = { "Outline", "OutlineOpen" },
	keys = { -- Example mapping to toggle outline
		{ "\\o", "<cmd>Outline<CR>", desc = "Toggle outline" },
	},
	config = function()
		require("outline").setup()
	end,
}
