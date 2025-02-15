return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				go = { "goimports", "gofumpt" },
				lua = { "stylua" },
				proto = { "buf" },
				python = { "black" },
				cmake = { "gersemi" },
				yaml = { "yamlfmt" },
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
			log_level = vim.log.levels.INFO,
			notify_on_error = true,
		})
	end,
}
