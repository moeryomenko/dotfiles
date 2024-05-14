return {
	{
		"nvim-neotest/neotest",
		event = "VeryLazy",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",

			"nvim-neotest/neotest-plenary",
			"nvim-neotest/neotest-vim-test",

			"nvim-neotest/nvim-nio",

			{
				"echasnovski/mini.indentscope",
				opts = function()
					-- disable indentation scope for the neotest-summary buffer
					vim.cmd([[ autocmd Filetype neotest-summary lua vim.b.miniindentscope_disable = true ]])
				end,
			},
		},
		opts = {
			icons = {
				child_indent = "│",
				child_prefix = "├",
				collapsed = "─",
				expanded = "╮",
				failed = "✘",
				final_child_indent = " ",
				final_child_prefix = "╰",
				non_collapsible = "─",
				passed = "✓",
				running = "",
				running_animated = { "/", "|", "\\", "-", "/", "|", "\\", "-" },
				skipped = "↓",
				unknown = "",
			},
			status = {
				enabled = true,
				signs = true,
				virtual_text = true,
			},
			floating = {
				enabled = true,
				border = "rounded",
				max_height = 0.9,
				max_width = 0.9,
				options = {},
			},
			-- output = { open_on_run = true },
			quickfix = {
				enabled = true,
				open = function()
					vim.cmd("Trouble quickfix")
				end,
			},
		},
		config = function(_, opts)
			if opts.adapters then
				local adapters = {}
				for name, config in pairs(opts.adapters or {}) do
					if type(name) == "number" then
						if type(config) == "string" then
							config = require(config)
						end
						adapters[#adapters + 1] = config
					elseif config ~= false then
						local adapter = require(name)
						if type(config) == "table" and not vim.tbl_isempty(config) then
							local meta = getmetatable(adapter)
							if adapter.setup then
								adapter.setup(config)
							elseif meta and meta.__call then
								adapter(config)
							else
								error("Adapter " .. name .. " does not support setup")
							end
						end
						adapters[#adapters + 1] = adapter
					end
				end
				opts.adapters = adapters
			end

			require("neotest").setup(opts)
		end,
		keys = require("core.keymaps").setup_neotest_keymaps(),
	},
}
