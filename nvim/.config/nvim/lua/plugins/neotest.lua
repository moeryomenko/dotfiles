return {
	{
		src = "https://github.com/nvim-neotest/nvim-nio",
	},
	{
		src = "https://github.com/nvim-lua/plenary.nvim",
	},
	{
		src = "https://github.com/antoinemadec/FixCursorHold.nvim",
	},
	{
		src = "https://github.com/nvim-neotest/neotest-plenary",
	},
	{
		src = "https://github.com/nvim-neotest/neotest-vim-test",
	},
	{
		src = "https://github.com/nvim-neotest/neotest",
		config = function()
			local function apply_adapter(adapter, config)
				if type(config) == "table" and not vim.tbl_isempty(config) then
					local meta = getmetatable(adapter)
					if adapter.setup then
						adapter.setup(config)
					elseif adapter.adapter then
						adapter.adapter(config)
						adapter = adapter.adapter
					elseif meta and meta.__call then
						adapter(config)
					else
						error("Adapter does not support setup")
					end
				end
				return adapter
			end

			local adapters = {}

			for _, name in ipairs({ "neotest-plenary", "neotest-vim-test" }) do
				adapters[#adapters + 1] = require(name)
			end

			for name, config in pairs(require("core.pack").neotest_adapters) do
				adapters[#adapters + 1] = apply_adapter(require(name), config)
			end

			require("neotest").setup({ adapters = adapters })

			vim.keymap.set("n", "<leader>ta", function() require("neotest").run.attach() end, { desc = "[t]est [a]ttach" })
			vim.keymap.set("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, { desc = "[t]est run [f]ile" })
			vim.keymap.set("n", "<leader>tA", function() require("neotest").run.run(vim.uv.cwd()) end, { desc = "[t]est [A]ll files" })
			vim.keymap.set("n", "<leader>tS", function() require("neotest").run.run({ suite = true }) end, { desc = "[t]est [S]uite" })
			vim.keymap.set("n", "<leader>tn", function() require("neotest").run.run() end, { desc = "[t]est [n]earest" })
			vim.keymap.set("n", "<leader>tl", function() require("neotest").run.run_last() end, { desc = "[t]est [l]ast" })
			vim.keymap.set("n", "<leader>ts", function() require("neotest").summary.toggle() end, { desc = "[t]est [s]ummary" })
			vim.keymap.set("n", "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, { desc = "[t]est [o]utput" })
			vim.keymap.set("n", "<leader>tO", function() require("neotest").output_panel.toggle() end, { desc = "[t]est [O]utput panel" })
			vim.keymap.set("n", "<leader>tt", function() require("neotest").run.stop() end, { desc = "[t]est [t]erminate" })
			vim.keymap.set("n", "<leader>td", function() require("neotest").run.run({ suite = false, strategy = "dap" }) end, { desc = "Debug nearest test" })
			vim.keymap.set("n", "<leader>tD", function() require("neotest").run.run({ vim.fn.expand("%"), strategy = "dap" }) end, { desc = "Debug current file" })
		end,
	},
}
