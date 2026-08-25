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
					vim.list_extend(opts.ensure_installed, { "gofumpt", "goimports", "gci", "golines" })
				end,
			},
		},
		ft = { "go", "gomod", "gowork", "gotmpl" },
		opts = {
			formatters_by_ft = {
				go = { "gofumpt", "goimports", "gci", "golines" },
			},
			formatters = {
				gofumpt = {
					prepend_args = { "-extra" },
				},
				gci = {
					args = {
						"write",
						"--skip-generated",
						"-s",
						"standard",
						"-s",
						"default",
						"--skip-vendor",
						"$FILENAME",
					},
				},
				goimports = {
					args = { "-srcdir", "$FILENAME" },
				},
				golines = {
					-- golines will use goimports as base formatter by default which is slow.
					-- see https://github.com/segmentio/golines/issues/33
					prepend_args = { "--base-formatter=gofumpt", "--ignore-generated", "--tab-len=1", "--max-len=120" },
				},
			},
		},
	},
	{
		"nvim-neotest/neotest",
		dependencies = {
			{
				"fredrikaverpil/neotest-golang",
				dependencies = {
					{
						"leoluz/nvim-dap-go",
						opts = {},
					},
				},
				branch = "main",
			},
		},
		opts = function(_, opts)
			opts.adapters = opts.adapters or {}
			opts.adapters["neotest-golang"] = {
				go_test_args = {
					"-v",
					"-race",
					"-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
				},
			}
		end,
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
					require("dap-go").setup({
						dap_configurations = {
							{
								type = "go",
								name = "Debug",
								request = "launch",
								program = "${file}",
							},
						},
						delve = {
							path = vim.fn.exepath("dlv"), -- Make sure this points to your updated delve
							initialize_timeout_sec = 20,
							args = {},
						},
					})
				end,
			},
		},
	},
}
