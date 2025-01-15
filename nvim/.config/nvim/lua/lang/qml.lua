return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			external = {
				qmlls = {},
			},
		},
	},
	{
		"Leon-Degel-Koehn/qmlformat.nvim",
		config = function()
			local qmlformat = require("qmlformat")
			-- you can define this however you want
			vim.keymap.set("n", "<leader>q", qmlformat.preview_qmlformat_changes, {})
		end,
	},
}
