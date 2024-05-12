return {
	"folke/neodev.nvim",
	dependencies = {
		{
			"williamboman/mason.nvim",
			opts = function(_, opts)
				opts.ensure_installed = opts.ensure_installed or {}
				vim.list_extend(opts.ensure_installed, { "lua-language-server", "stylua" })
			end,
		},
	},
	ft = { "lua", "vim" },
	config = function()
		require("neodev").setup({
			library = {
				enabled = true,
				runtime = true,
				types = true,
				plugins = true,
			},
			setup_jsonls = true,
			override = function(_, _) end,
			lspconfig = true,
			pathStrict = true,
		})
	end,
}
