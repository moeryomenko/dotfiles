return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"leoluz/nvim-dap-go",
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
		"theHamsta/nvim-dap-virtual-text",
		"rcarriga/cmp-dap",
		"LiadOz/nvim-dap-repl-highlights",
	},
	cmd = { "DapUIToggle", "DapToggleRepl", "DapToggleBreakpoint" },
	keys = {
		{ "<F5>", ":lua require'dap'.continue()<CR>" },
		{ "<F10>", ":lua require'dap'.step_over()<CR>" },
		{ "<F11>", ":lua require'dap'.step_into()<CR>" },
		{ "<F12>", ":lua require'dap'.step_out()<CR>" },
		{ "<leader>b", ":lua require'dap'.toggle_breakpoint()<CR>" },
		{ "<leader>B", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>" },
		{ "<leader>lp", ":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>" },
		{ "<leader>ro", ":lua require'dap'.repl.open()<CR>" },
		{ "<leader>dt", ":lua require('dap-go').debug_test()<CR>" },
		{ "<leader>dr", ":lua require('dap').run()<CR>" },
		{ "<leader>do", ":DapUIToggle<CR>" },
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")
		local icons = require("core.icons")
		dapui.setup({
			icons = { expanded = icons.ui.ArrowClosed, collapsed = icons.ui.ArrowOpen },
			windows = { indent = 1 },
			layouts = {
				{
					elements = {
						-- Elements can be strings or table with id and size keys.
						{ id = "scopes", size = 0.25 },
						"breakpoints",
						-- "stacks",
						-- "watches",
					},
					size = 60,
					position = "left",
				},
				{
					elements = {
						"repl",
						"console",
					},
					size = 0.25, -- 25% of total lines
					position = "bottom",
				},
			},
			render = {
				max_type_length = nil, -- Can be integer or nil.
			},
		})

		vim.fn.sign_define(
			"DapBreakpoint",
			{ text = icons.ui.Bug, texthl = "DiagnosticSignError", linehl = "", numhl = "" }
		)

		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end

		require("dap-go").setup()

		dap.adapters.lldb = {
			type = "executable",
			command = "/usr/bin/lldb-vscode", -- adjust as needed, must be absolute path
			env = {
				LLDB_LAUNCH_FLAG_LAUNCH_IN_TTY = "YES",
			},
			name = "lldb",
		}
		dap.configurations.cpp = {
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
		}
		dap.configurations.c = dap.configurations.cpp

		dap.configurations.scala = {
			{
				type = "scala",
				request = "launch",
				name = "RunOrTest",
				metals = {
					runType = "runOrTestFile",
				},
			},
			{
				type = "scala",
				request = "launch",
				name = "Test Target",
				metals = {
					runType = "testTarget",
				},
			},
		}

		vim.api.nvim_create_user_command("DapUIToggle", function()
			require("dapui").toggle()
		end, {})
	end,
}
