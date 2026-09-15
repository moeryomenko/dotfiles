local icons = require("core.icons")

return {
	{
		src = "https://github.com/mfussenegger/nvim-dap",
		config = function()
			local dap = require("dap")

			vim.fn.sign_define(
				"DapBreakpoint",
				{ text = icons.ui.Bug, texthl = "DiagnosticSignError", linehl = "", numhl = "" }
			)

			vim.keymap.set("n", "<F5>", function()
				dap.continue()
			end, { desc = "Debug: Continue" })
			vim.keymap.set("n", "<F10>", function()
				dap.step_over()
			end, { desc = "Debug: Step over" })
			vim.keymap.set("n", "<F11>", function()
				dap.step_into()
			end, { desc = "Debug: Step into" })
			vim.keymap.set("n", "<F12>", function()
				dap.step_out()
			end, { desc = "Debug: Step out" })
			vim.keymap.set("n", "\\b", function()
				dap.toggle_breakpoint()
			end, { desc = "Debug: Toggle breakpoint" })
			vim.keymap.set("n", "\\B", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Debug: Conditional breakpoint" })
			vim.keymap.set("n", "\\lp", function()
				dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
			end, { desc = "Debug: Log point" })
			vim.keymap.set("n", "\\ro", function()
				dap.repl.open()
			end, { desc = "Debug: Repl" })
			vim.keymap.set("n", "\\dr", function()
				dap.run()
			end, { desc = "Debug: Run" })
			vim.keymap.set("n", "\\do", function()
				require("dapui").toggle()
			end, { desc = "Debug: Toggle UI" })

			require("nvim-dap-projects").search_project_config()
		end,
	},
	{
		src = "https://github.com/nvim-neotest/nvim-nio",
	},
	{
		src = "https://github.com/rcarriga/nvim-dap-ui",
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup({
				icons = { expanded = icons.ui.ArrowClosed, collapsed = icons.ui.ArrowOpen },
				windows = { indent = 1 },
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.25 },
							"breakpoints",
						},
						size = 60,
						position = "left",
					},
					{
						elements = {
							"repl",
						},
						size = 0.25,
						position = "bottom",
					},
				},
				render = {
					max_type_length = nil,
				},
			})

			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open({})
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close({})
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close({})
			end

			vim.api.nvim_create_user_command("DapUIToggle", function()
				dapui.toggle()
			end, {})
		end,
	},
	{ src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
	{ src = "https://github.com/LiadOz/nvim-dap-repl-highlights" },
	{ src = "https://github.com/ldelossa/nvim-dap-projects" },
}
