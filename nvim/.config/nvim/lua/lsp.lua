local api = vim.api
local cmd = vim.cmd

require("nvim-treesitter.configs").setup({
	-- One of "all", "maintained" (parsers with maintainers), or a list of languages
	ensure_installed = {
		"bash",
		"cmake",
		"cpp",
		"json",
		"rust",
		"toml",
		"yaml",
	},

	-- Install languages synchronously (only applied to `ensure_installed`)
	sync_install = true,

	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
	textobjects = {
		select = {
			enable = true,
			-- Automatically jump forward to textobj, similar to targets.vim
			lookahead = true,
			keymaps = {
				-- You can use the capture groups defined in textobjects.scm
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				-- You can optionally set descriptions to the mappings (used in the desc parameter of
				-- nvim_buf_set_keymap) which plugins like which-key display
				["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
			},
			-- You can choose the select mode (default is charwise 'v')
			--
			-- Can also be a function which gets passed a table with the keys
			-- * query_string: eg '@function.inner'
			-- * method: eg 'v' or 'o'
			-- and should return the mode ('v', 'V', or '<c-v>') or a table
			-- mapping query_strings to modes.
			selection_modes = {
				["@parameter.outer"] = "v", -- charwise
				["@function.outer"] = "V", -- linewise
				["@class.outer"] = "<c-v>", -- blockwise
			},
			-- If you set this to `true` (default is `false`) then any textobject is
			-- extended to include preceding or succeeding whitespace. Succeeding
			-- whitespace has priority in order to act similarly to eg the built-in
			-- `ap`.
			--
			-- Can also be a function which gets passed a table with the keys
			-- * query_string: eg '@function.inner'
			-- * selection_mode: eg 'v'
			-- and should return true of false
			include_surrounding_whitespace = true,
		},
		swap = {
			enable = true,
			swap_next = {
				["<leader>a"] = "@parameter.inner",
			},
			swap_previous = {
				["<leader>A"] = "@parameter.inner",
			},
		},
		move = {
			enable = true,
			set_jumps = true, -- whether to set jumps in the jumplist
			goto_next_start = {
				["]m"] = "@function.outer",
				["]]"] = { query = "@class.outer", desc = "Next class start" },
			},
			goto_next_end = {
				["]M"] = "@function.outer",
				["]["] = "@class.outer",
			},
			goto_previous_start = {
				["[m"] = "@function.outer",
				["[["] = "@class.outer",
			},
			goto_previous_end = {
				["[M"] = "@function.outer",
				["[]"] = "@class.outer",
			},
		},
		lsp_interop = {
			enable = true,
			border = "none",
			peek_definition_code = {
				["<leader>df"] = "@function.outer",
				["<leader>dF"] = "@class.outer",
			},
		},
	},
})

local nvim_lsp = require("lspconfig")
local on_attach = function(client, bufnr)
	-- Set autocommands conditional on server_capabilities
	if client.server_capabilities.document_highlight then
		vim.api.nvim_exec(
			[[
	hi LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
	hi LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
	hi LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
	augroup lsp_document_highlight
		autocmd! * <buffer>
		autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
		autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
	augroup END
	]],
			false
		)
	end
end

-- Add additional capabilities supported by nvim-cmp
local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

require("rust-tools").setup({
	tools = {
		executor = require("rust-tools.executors").termopen,
		reload_workspace_from_cargo_toml = true,
		inlay_hints = {
			auto = true,
			show_parameter_hints = true,
		},
	},

	server = {
		on_attach = on_attach,
		settings = {
			["rust-analyzer"] = {
				checkOnSave = { command = "clippy" },
			},
		},
	},
})

nvim_lsp.qmlls.setup({
	on_attach = on_attach,
	capabilities = capabilities,
})

nvim_lsp.neocmake.setup({
	on_attach = on_attach,
	capabilities = capabilities,
})

require("mason-lspconfig").setup()

-- the above is enough, but if you want to replicate the "on_server_ready" behaviour
-- where your installed servers are setup "automatically" you can do the following
require("mason-lspconfig").setup_handlers({
	-- default handler - setup with default settings
	function(server_name)
		nvim_lsp[server_name].setup({
			on_attach = on_attach,
			capabilities = capabilities,
		})
	end,
})

require("clangd_extensions").setup({
	server = {
		on_attach = on_attach,
		capabilities = capabilities,
	},
	extensions = {
		-- defaults:
		-- Automatically set inlay hints (type hints)
		autoSetHints = true,
		-- These apply to the default ClangdSetInlayHints command
		inlay_hints = {
			-- Only show inlay hints for the current line
			only_current_line = false,
			-- Event which triggers a refersh of the inlay hints.
			-- You can make this "CursorMoved" or "CursorMoved,CursorMovedI" but
			-- not that this may cause  higher CPU usage.
			-- This option is only respected when only_current_line and
			-- autoSetHints both are true.
			only_current_line_autocmd = "CursorHold",
			-- whether to show parameter hints with the inlay hints or not
			show_parameter_hints = true,
			-- prefix for parameter hints
			parameter_hints_prefix = "<- ",
			-- prefix for all the other hints (type, chaining)
			other_hints_prefix = "=> ",
			-- whether to align to the length of the longest line in the file
			max_len_align = false,
			-- padding from the left if max_len_align is true
			max_len_align_padding = 1,
			-- whether to align to the extreme right or not
			right_align = false,
			-- padding from the right if right_align is true
			right_align_padding = 7,
			-- The color of the hints
			highlight = "Comment",
			-- The highlight group priority for extmark
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
		{ name = "luasnip" },
		{ name = "rg" },
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
			require("clangd_extensions.cmp_scores"),
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
