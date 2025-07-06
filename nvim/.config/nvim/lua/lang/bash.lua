return {
	{
		"stevearc/conform.nvim",
		dependencies = {
			{
				"williamboman/mason.nvim",
				opts = function(_, opts)
					opts.ensure_installed = opts.ensure_installed or {}
					vim.list_extend(opts.ensure_installed, { "shellharden" })
				end,
			},
		},
		ft = { "bash", "shell", "sh" },
		opts = {
			formatters_by_ft = {
				sh = { "shellharden" },
				shell = { "shellharden" },
				bash = { "shellharden" },
			},
		},
	},
}
