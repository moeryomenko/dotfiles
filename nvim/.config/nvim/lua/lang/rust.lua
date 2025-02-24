return {
	-- Extend auto completion
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			{
				"Saecki/crates.nvim",
				tag = "stable",
				event = { "BufRead Cargo.toml" },
				opts = {},
			},
		},
		---@param opts cmp.ConfigSchema
		opts = function(_, opts)
			opts.sources = opts.sources or {}
			table.insert(opts.sources, { name = "crates" })
		end,
	},
	-- Ensure Rust debugger is installed
	{
		"williamboman/mason.nvim",
		optional = true,
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, { "codelldb" })
		end,
	},
}
