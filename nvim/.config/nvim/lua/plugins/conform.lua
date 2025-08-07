return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
	config = function(_, opts)
		local conf = {
			formatters_by_ft = {
				lua = { "stylua" },
				proto = { "buf" },
				python = { "black" },
				cmake = { "gersemi" },
				yaml = { "yamlfmt" },
				sql = { "sqruff" },
			},
			formatters = {},
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
			log_level = vim.log.levels.INFO,
			notify_on_error = true,
		}

		if opts.formatters_by_ft ~= nil then
			local merged = require("core.utils").deep_tbl_extend(conf.formatters_by_ft, opts.formatters_by_ft)
			conf.formatters_by_ft = merged
		end

		if opts.formatters ~= nil then
			local merged = require("core.utils").deep_tbl_extend(conf.formatters, opts.formatters)
			conf.formatters = merged
		end

		require("conform").setup(conf)
	end,
}
