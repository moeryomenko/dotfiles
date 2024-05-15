return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"williamboman/mason-lspconfig.nvim",
				dependencies = {
					{
						"williamboman/mason.nvim",
					},
					{
						"artemave/workspace-diagnostics.nvim",
						enabled = true,
					},
				},
				opts = function(_, opts)
					opts.ensure_installed = opts.ensure_installed or {}
					vim.list_extend(opts.ensure_installed, { "neocmakelsp" })
				end,
			},
		},
		ft = { "cmake" },
	},
}
