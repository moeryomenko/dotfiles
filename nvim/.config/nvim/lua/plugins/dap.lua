local icons = require("core.icons")

return {
	"mfussenegger/nvim-dap",
	event = "VeryLazy",
	dependencies = {
		{
			"rcarriga/nvim-dap-ui",
			dependencies = {
				"nvim-neotest/nvim-nio",
			},
			opts = {},
			config = function(_, opts)
				-- setup dap config by VsCode launch.json file
				-- require("dap.ext.vscode").load_launchjs()
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
							size = 0.25, -- 25% of total lines
							position = "bottom",
						},
					},
					render = {
						max_type_length = nil, -- Can be integer or nil.
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
					require("dapui").toggle()
				end, {})
			end,
		},
		{
			"jay-babu/mason-nvim-dap.nvim",
			dependencies = {
				"williamboman/mason.nvim",
				-- "mfussenegger/nvim-dap",
			},
			cmd = { "DapInstall", "DapUninstall" },
			opts = {
				-- Makes a best effort to setup the various debuggers with
				-- reasonable debug configurations
				automatic_installation = true,

				-- You can provide additional configuration to the handlers,
				-- see mason-nvim-dap README for more information
				handlers = {},

				-- You'll need to check that you have the required things installed
				-- online, please don't ask me how to install them :)
				ensure_installed = {
					-- Update this to ensure that you have the debuggers for the langs you want
				},
			},
		},
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
		{ "\\b", ":lua require'dap'.toggle_breakpoint()<CR>" },
		{ "\\B", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>" },
		{ "\\lp", ":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>" },
		{ "\\ro", ":lua require'dap'.repl.open()<CR>" },
		{ "\\dr", ":lua require('dap').run()<CR>" },
		{ "\\dt", ":lua require('dap-go').debug_test()<CR>" },
		{ "\\do", ":DapUIToggle<CR>" },
	},
	config = function(_, opts)
		local dap = require("dap")

		vim.fn.sign_define(
			"DapBreakpoint",
			{ text = icons.ui.Bug, texthl = "DiagnosticSignError", linehl = "", numhl = "" }
		)
		if opts.adapters ~= nil then
			local merged = require("core.utils").deep_tbl_extend(dap.adapters, opts.adapters)
			dap.adapters = merged
		end

		if opts.configurations ~= nil then
			local merged = require("core.utils").deep_tbl_extend(dap.configurations, opts.configurations)
			dap.configurations = merged
		end
	end,
}
