vim.api.nvim_create_autocmd("FileType", {
	pattern = { "go", "gomod", "gowork", "gotmpl", "proto" },
	callback = function()
		-- set go specific options
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.colorcolumn = "120"
	end,
})

return {
	{
		"stevearc/conform.nvim",
		dependencies = {
			{
				"williamboman/mason.nvim",
				opts = function(_, opts)
					opts.ensure_installed = opts.ensure_installed or {}
					vim.list_extend(opts.ensure_installed, { "gofumpt", "goimports" })
				end,
			},
		},
		ft = { "go", "gomod", "gowork", "gotmpl" },
		opts = {
			formatters_by_ft = {
				go = { "gofumpt", "goimports" },
			},
			formatters = {
				gofumpt = {
					prepend_args = { "-extra" },
				},
				goimports = {
					args = { "-srcdir", "$FILENAME" },
				},
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"williamboman/mason-lspconfig.nvim",
				dependencies = {
					{
						"williamboman/mason.nvim",
					},
				},
				opts = function(_, opts)
					opts.ensure_installed = opts.ensure_installed or {}
					vim.list_extend(opts.ensure_installed, { "gopls" })
				end,
			},
		},
		ft = { "go", "gomod", "gowork", "gotmpl" },
	},
	{
		"nvim-neotest/neotest",
		ft = { "go" },
		dependencies = {
			"fredrikaverpil/neotest-golang",
		},
		opts = function(_, opts)
			opts.adapters = opts.adapters or {}
			opts.adapters["neotest-golang"] = {
				go_test_args = {
					"-v",
					"-race",
					"-count=1",
					"-timeout=60s",
					"-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
				},
				dap_go_enabled = true,
			}
		end,
	},
	{
		"andythigpen/nvim-coverage",
		ft = { "go" },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			-- https://github.com/andythigpen/nvim-coverage/blob/main/doc/nvim-coverage.txt
			auto_reload = true,
			lang = {
				go = {
					coverage_file = vim.fn.getcwd() .. "/coverage.out",
				},
			},
		},
	},
	{
		"mfussenegger/nvim-dap",
		ft = { "go" },
		dependencies = {
			{
				"jay-babu/mason-nvim-dap.nvim",
				dependencies = {
					"williamboman/mason.nvim",
				},
				opts = {
					ensure_installed = { "delve" },
				},
			},
			{
				"leoluz/nvim-dap-go",
				config = function()
					require("dap-go").setup()
				end,
			},
		},
	},
}
