return {
	{
		src = "https://github.com/RRethy/nvim-treesitter-endwise",
	},
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		version = "main",
		config = function()
			require("nvim-treesitter").setup({})

			vim.api.nvim_create_autocmd("FileType", {
				callback = function()
					pcall(vim.treesitter.start)
				end,
			})
		end,
	},
}