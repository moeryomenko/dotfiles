return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	branch = "main",
	dependencies = {
		"RRethy/nvim-treesitter-endwise",
	},
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("nvim-treesitter.config").setup({
			ensure_installed = {
				"bash",
				"cmake",
				"c",
				"cpp",
				"fish",
				"go",
				"vimdoc",
				"lua",
				"json",
				"markdown",
				"markdown_inline",
				"python",
				"rust",
				"yaml",
			},
			sync_install = false,
			ignore_install = {},
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
			},
			indent = { enable = true },
		})
	end,
}
