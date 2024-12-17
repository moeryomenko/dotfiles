return {
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
			vim.list_extend(opts.ensure_installed, { "zls" })
		end,
	},
	{
		"mfussenegger/nvim-dap",
		ft = { "zig" },
		dependencies = {
			{
				"jay-babu/mason-nvim-dap.nvim",
				dependencies = {
					"williamboman/mason.nvim",
				},
				opts = {
					ensure_installed = { "codelldb" },
				},
			},
		},
		opts = {
			adapters = {
				lldb = {
					type = "executable",
					command = "/usr/bin/lldb-dap", -- adjust as needed, must be absolute path
					env = {
						LLDB_LAUNCH_FLAG_LAUNCH_IN_TTY = "YES",
					},
					name = "lldb",
				},
			},
			configurations = {
				zig = {
					{
						name = "Launch",
						type = "lldb",
						request = "launch",
						program = function()
							return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
						end,
						cwd = "${workspaceFolder}",
						stopOnEntry = false,
						args = {},
					},
				},
			},
		},
	},
}
