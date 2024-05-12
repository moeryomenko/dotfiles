return {
	"scalameta/nvim-metals",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	ft = { "scala", "sbt", "java" },
	config = function()
		local metals = require("metals")
		local dap = require("dap")
		local metals_config = metals.bare_config()
		metals_config.on_attach = function(client, bufnr)
			metals.setup_dap()

			map("n", "<leader>ws", function()
				metals.hover_worksheet()
			end)

			-- all workspace diagnostics
			map("n", "<leader>aa", vim.diagnostic.setqflist)

			-- all workspace errors
			map("n", "<leader>ae", function()
				vim.diagnostic.setqflist({ severity = "E" })
			end)

			-- all workspace warnings
			map("n", "<leader>aw", function()
				vim.diagnostic.setqflist({ severity = "W" })
			end)

			-- buffer diagnostics only
			map("n", "<leader>d", vim.diagnostic.setloclist)

			map("n", "[c", function()
				vim.diagnostic.goto_prev({ wrap = false })
			end)

			map("n", "]c", function()
				vim.diagnostic.goto_next({ wrap = false })
			end)

			-- Example mappings for usage with nvim-dap. If you don't use that, you can
			-- skip these
			map("n", "<leader>dc", function()
				dap.continue()
			end)

			map("n", "<leader>dr", function()
				dap.repl.toggle()
			end)

			map("n", "<leader>dK", function()
				require("dap.ui.widgets").hover()
			end)

			map("n", "<leader>dt", function()
				dap.toggle_breakpoint()
			end)

			map("n", "<leader>dso", function()
				dap.step_over()
			end)

			map("n", "<leader>dsi", function()
				dap.step_into()
			end)

			map("n", "<leader>dl", function()
				dap.run_last()
			end)
		end

		metals_config.settings = {
			showImplicitArguments = true,
			excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
		}

		metals_config.init_options.statusBarProvider = "off"

		metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()

		local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "scala", "sbt", "java" },
			callback = function()
				metals.initialize_or_attach(metals_config)
			end,
			group = nvim_metals_group,
		})
	end,
}
