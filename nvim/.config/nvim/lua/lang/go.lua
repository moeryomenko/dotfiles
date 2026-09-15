local pack = require("core.pack")

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "go", "gomod", "gowork", "gotmpl", "proto" },
	callback = function()
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.colorcolumn = "120"
	end,
})

pack.neotest_adapters["neotest-golang"] = {
	go_test_args = {
		"-v",
		"-race",
		"-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
	},
}

return {
	{
		src = "https://github.com/williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		src = "https://github.com/stevearc/conform.nvim",
		config = function()
			local conform = require("conform")

			conform.formatters_by_ft.go = { "gofumpt", "goimports", "gci", "golines" }
			conform.formatters.gofumpt = { prepend_args = { "-extra" } }
			conform.formatters.gci = {
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
			}
			conform.formatters.goimports = { args = { "-srcdir", "$FILENAME" } }
			conform.formatters.golines = {
				prepend_args = { "--base-formatter=gofumpt", "--ignore-generated", "--tab-len=1", "--max-len=120" },
			}
		end,
	},
	{
		src = "https://github.com/fredrikaverpil/neotest-golang",
		version = "main",
	},
	{
		src = "https://github.com/jay-babu/mason-nvim-dap.nvim",
		config = function()
			require("mason-nvim-dap").setup({
				-- delve is managed by the Go toolchain (go install); mason's
				-- copy lags behind and dlv refuses to debug newer Go versions.
				ensure_installed = {},
			})
		end,
	},
	{
		src = "https://github.com/leoluz/nvim-dap-go",
		config = function()
			local go_bin = vim.fn.expand("~/go/bin")
			local dlv = vim.fn.executable(go_bin .. "/dlv") == 1 and (go_bin .. "/dlv") or vim.fn.exepath("dlv")

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
					path = dlv,
					initialize_timeout_sec = 20,
					args = { "--check-go-version=false" },
				},
			})

			vim.keymap.set("n", "\\dt", function() require("dap-go").debug_test() end, { desc = "Debug: Go test" })
		end,
	},
}
