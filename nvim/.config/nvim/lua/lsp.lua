local dap = require("dap")
require("dap-go").setup()

require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"bash",
		"java",
		"json",
		"go",
		"gomod",
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
mason_lsp.setup()
mason_lsp.setup_handlers({
	function(server_name)
		if server_name ~= "jdtls" then
			nvim_lsp[server_name].setup({
				capabilities = capabilities,
			})
		end
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

local fn = vim.fn
local mason_registry = require("mason-registry")
local project_name = fn.fnamemodify(fn.getcwd(), ":p:h:t")
local jdtls_dir = mason_registry.get_package("jdtls"):get_install_path()
local java_debug = mason_registry.get_package("java-debug-adapter"):get_install_path()
local java_test = mason_registry.get_package("java-test"):get_install_path()
local workspace_dir = jdtls_dir .. "/workspace/" .. project_name
local java_bundles = {
	fn.glob(java_debug .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", true),
}

vim.list_extend(java_bundles, vim.split(fn.glob(java_test .. "/extension/server/*.jar", true), "\n"))

local java_config = {
	cmd = {
		"java",
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-Xms1g",
		"-jar",
		jdtls_dir .. "/plugins/org.eclipse.equinox.launcher_1.6.400.v20210924-0641.jar",
		"-configuration",
		jdtls_dir .. "/config_linux",
		"-data",
		workspace_dir,
		"-javaagent",
		jdtls_dir .. "/lombok.jar",
	},
	settings = {
		java = {
			signatureHelp = { enabled = true },
			configuration = {
				runtimes = {
					{
						name = "JavaSE-17",
						path = "/home/moeryomenko/.sdkman/candidates/java/17.0.6-librca",
					},
					{
						name = "JavaSE-19",
						path = "/home/moeryomenko/.sdkman/candidates/java/19.0.2-librca",
					},
				},
			},
		},
	},
	root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew" }),
	init_options = {
		bundles = java_bundles,
	},
	capabilities = capabilities,
}

vim.api.nvim_create_autocmd("FileType", {
	pattern = "java",
	callback = function()
		local jdtls = require("jdtls")
		jdtls.start_or_attach(java_config)
		jdtls.setup_dap({ hotcodereplace = "auto" })
	end,
})
