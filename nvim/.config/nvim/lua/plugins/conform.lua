return {
	{
		src = "https://github.com/stevearc/conform.nvim",
		config = function()
			local conf = {
				formatters_by_ft = {
					lua = { "stylua" },
					proto = { "buf" },
					python = { "black" },
					cmake = { "gersemi" },
					yaml = { "yamlfmt" },
					sql = { "sqruff" },
					terraform = { "terraform" },
					hcl = { "hclfmt" },
				},
				formatters = {},
				format_on_save = {
					timeout_ms = 500,
					lsp_fallback = true,
				},
				log_level = vim.log.levels.INFO,
				notify_on_error = true,
			}

			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

			require("conform").setup(conf)
		end,
	},
}
