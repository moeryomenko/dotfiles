local dap = require("dap")
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

local Path = require("plenary.path")
require("tasks").setup({
	default_params = {
		cmake = {
			cmd = "cmake",
			build_dir = tostring(Path:new("{cwd}", "build")),
			build_type = "Debug",
			dap_name = "lldb",
			args = {
				configure = {
					"-D",
					"CMAKE_EXPORT_COMPILE_COMMANDS=1",
					"-G",
					"Ninja",
					"-D",
					'CMAKE_EXE_LINKER_FLAGS_INIT="-fuse-ld=mold"',
					"-D",
					'CMAKE_SHARED_LINKER_FLAGS_INIT="-fuse-ld=mold"',
					"-D",
					"CMAKE_C_COMPILER=clang",
					"-D",
					"CMAKE_CXX_COMPILER=clang++",
					"-D",
					"CMAKE_C_COMPILER_LAUNCHER='/usr/bin/ccache'",
					"-D",
					"CMAKE_CXX_COMPILER_LAUNCHER='/usr/bin/ccache'",
				},
			},
		},
	},
	save_before_run = true,
	params_file = "neovim.json",
	quickfix = {
		pos = "botright",
		height = 12,
	},
	dap_open_command = function()
		return require("dapui").open()
	end,
})

require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"bash",
		"c",
		"cpp",
		"lua",
		"glsl",
		"json",
		"rust",
		"toml",
		"yaml",
	},
	sync_install = true,
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
})

require("hlargs").setup()

local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

require("neodev").setup()

local nvim_lsp = require("lspconfig")
local mason_lsp = require("mason-lspconfig")

mason_lsp.setup_handlers({
	function(server_name)
		nvim_lsp[server_name].setup({ capabilities = capabilities })
	end,
	["clangd"] = function()
		require("clangd_extensions").setup({
			server = {
				capabilities = capabilities,
			},
			extensions = {
				autoSetHints = true,
				inlay_hints = {
					only_current_line = true,
					only_current_line_autocmd = "CursorHold",
					show_parameter_hints = true,
					parameter_hints_prefix = "<- ",
					other_hints_prefix = "=> ",
					max_len_align = false,
					max_len_align_padding = 1,
					right_align = false,
					right_align_padding = 7,
					highlight = "Comment",
					priority = 100,
				},
				ast = {
					role_icons = {
						type = "",
						declaration = "",
						expression = "",
						specifier = "",
						statement = "",
						["template argument"] = "",
					},
					kind_icons = {
						Compound = "",
						Recovery = "",
						TranslationUnit = "",
						PackExpansion = "",
						TemplateTypeParm = "",
						TemplateTemplateParm = "",
						TemplateParamObject = "",
					},
					highlights = {
						detail = "Comment",
					},
					memory_usage = {
						border = "none",
					},
					symbol_info = {
						border = "none",
					},
				},
			},
		})
	end,
	["rust_analyzer"] = function()
		require("rust-tools").setup({
			tools = {
				reload_workspace_from_cargo_toml = true,
			},
			dap = {
				adapter = {
					type = "executable",
					command = "lldb-vscode",
					name = "rt_lldb",
				},
			},
			capabilities = capabilities,
		})
	end,
})

-- luasnip setup
local luasnip = require("luasnip")
require("luasnip.loaders.from_vscode").load()

local lspkind = require("lspkind")

-- nvim-cmp setup
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
local cmp = require("cmp")
cmp.setup({
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	mapping = {
		["<C-p>"] = cmp.mapping.select_prev_item(),
		["<C-n>"] = cmp.mapping.select_next_item(),
		["<C-d>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.close(),
		["<CR>"] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Replace,
			select = true,
		}),
		["<Tab>"] = function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_jumpable() then
				vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true), "")
			else
				fallback()
			end
		end,
		["<S-Tab>"] = function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.jumpable(-1) then
				vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
			else
				fallback()
			end
		end,
	},
	sources = {
		{ name = "nvim_lsp" },
		{ name = "nvim_lsp_signature_help" },
		{ name = "luasnip" },
		{ name = "rg" },
		{ name = "vim-dadbod-completion" },
	},
	formatting = {
		format = lspkind.cmp_format({
			mode = "symbol_text",
			maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
			-- The function below will be called before any actual modifications from lspkind
			-- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
			before = function(_, vim_item)
				return vim_item
			end,
		}),
	},
	sorting = {
		comparators = {
			cmp.config.compare.offset,
			cmp.config.compare.exact,
			cmp.config.compare.recently_used,
			cmp.config.compare.kind,
			cmp.config.compare.sort_text,
			cmp.config.compare.length,
			cmp.config.compare.order,
		},
	},
})

cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

cmp.setup.filetype({ "dap-repl", "dapui_watches" }, {
	sources = {
		{ name = "dap" },
	},
})
