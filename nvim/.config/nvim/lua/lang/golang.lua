local function find_file(filename, excluded_dirs)
	if not excluded_dirs then
		excluded_dirs = { ".git", "node_modules", ".venv" }
	end
	local exclude_str = ""
	for _, dir in ipairs(excluded_dirs) do
		exclude_str = exclude_str .. " --exclude " .. dir
	end
	local command = "fd --hidden --no-ignore"
		.. exclude_str
		.. " '"
		.. filename
		.. "' "
		.. vim.fn.getcwd()
		.. " | head -n 1"
	--  local command = "fd --hidden --no-ignore '" .. filename .. "' " .. vim.fn.getcwd() .. " | head -n 1"
	local file = io.popen(command):read("*l")
	local path = file and file or nil

	return path
end

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
				opts = {},
			},
		},
		opts = {
			configurations = {
				go = {
					-- See require("dap-go") source for full dlv setup.
					{
						type = "go",
						name = "Debug test (manually enter test name)",
						request = "launch",
						mode = "test",
						program = "./${relativeFileDirname}",
						args = function()
							local testname = vim.fn.input("Test name (^regexp$ ok): ")
							return { "-test.run", testname }
						end,
					},
				},
			},
		},
	},
}
