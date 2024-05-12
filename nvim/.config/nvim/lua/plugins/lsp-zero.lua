return {
	"VonHeikemen/lsp-zero.nvim",
	dependencies = {
		"neovim/nvim-lspconfig",
		"williamboman/mason-lspconfig.nvim",
	},
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lsp_zero = require("lsp-zero")
		lsp_zero.on_attach(function(_, bufnr)
			lsp_zero.default_keymaps({ buffer = bufnr })
		end)

		vim.diagnostic.config({
			virtual_text = false,
			signs = true,
			update_in_insert = false,
			underline = true,
			severity_sort = true,
			float = {
				focusable = false,
				style = "minimal",
				border = "rounded",
				source = "always",
				header = "",
				prefix = "",
			},
		})

		lsp_zero.set_sign_icons({
			error = "✘",
			warn = "▲",
			hint = "⚑",
			info = "",
		})

		require("mason").setup({})
		require("mason-lspconfig").setup({
			ensure_installed = {},
			handlers = {
				lsp_zero.default_setup,
				lua_ls = function()
					local lua_opts = lsp_zero.nvim_lua_ls()
					local custom_options = {
						enable = true,
						defaultConfig = {
							align_continuous_assign_statement = false,
							align_continuous_rect_table_field = false,
							align_array_table = false,
						},
					}
					lua_opts.settings.Lua.format = custom_options
					require("lspconfig").lua_ls.setup(lua_opts)
				end,
			},
		})
	end,
}
