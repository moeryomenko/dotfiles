local ensure_packer = function()
	local fn = vim.fn
	local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
	if fn.empty(fn.glob(install_path)) > 0 then
		fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
		vim.cmd([[packadd packer.nvim]])
		return true
	end
	return false
end

local packer_bootstrap = ensure_packer()

local packer = require("packer")

packer.startup(function(use)
	use("wbthomason/packer.nvim")
	use("nvim-lua/plenary.nvim")

	-- UI plugins.
	use("folke/tokyonight.nvim")
	use("AlexvZyl/nordic.nvim")
	use({
		"nvim-tree/nvim-tree.lua",
		requires = {
			"nvim-tree/nvim-web-devicons",
		},
		tag = "nightly",
	})
	use("simrat39/symbols-outline.nvim")
	use("yamatsum/nvim-cursorline")
	use("nvim-lualine/lualine.nvim")
	use({ "akinsho/bufferline.nvim", tag = "v3.*" })
	use("tiagovla/scope.nvim")
	use({
		"kwkarlwang/bufresize.nvim",
		config = function()
			require("bufresize").setup()
		end,
	})
	use("mrjones2014/smart-splits.nvim")
	use({
		"karb94/neoscroll.nvim",
		config = function()
			require("neoscroll").setup()
		end,
	})
	use("gelguy/wilder.nvim")
	-- telescope plugins.
	use({
		"nvim-telescope/telescope.nvim",
		"nvim-telescope/telescope-ui-select.nvim",
		"olacin/telescope-gitmoji.nvim",
		"LukasPietzschmann/telescope-tabs",
	})

	-- typing improvements.
	use("machakann/vim-sandwich")
	use({
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup()
		end,
	})
	use({
		"ThePrimeagen/refactoring.nvim",
		config = function()
			require("refactoring").setup({
				prompt_func_return_type = {
					go = true,
				},
				prompt_func_param_type = {
					go = true,
				},
			})
		end,
	})

	-- git integration.
	use("kdheepak/lazygit.nvim")
	use("tpope/vim-fugitive")
	use({
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
		end,
	})

	-- LSP plugins.
	use("neovim/nvim-lspconfig")
	use({
		"williamboman/mason.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"jose-elias-alvarez/null-ls.nvim",
		"jayp0521/mason-null-ls.nvim",
		"williamboman/mason-lspconfig.nvim",
	})
	use({
		"glepnir/lspsaga.nvim",
		branch = "main",
		config = function()
			require("lspsaga").setup({})
		end,
	})
	use({
		"ray-x/go.nvim",
		config = function()
			require("go").setup()
		end,
	})
	use("https://git.sr.ht/~p00f/clangd_extensions.nvim")
	use("mfussenegger/nvim-jdtls")
	use("ray-x/guihua.lua")
	use("folke/neodev.nvim")
	use("simrat39/rust-tools.nvim")
	use("Saecki/crates.nvim")
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-buffer")
	use("hrsh7th/cmp-path")
	use("hrsh7th/cmp-cmdline")
	use("hrsh7th/nvim-cmp")
	use("hrsh7th/cmp-nvim-lsp-signature-help")
	use("lukas-reineke/cmp-rg")
	use("onsails/lspkind-nvim")
	use("saadparwaiz1/cmp_luasnip")
	use("L3MON4D3/LuaSnip")
	use("rafamadriz/friendly-snippets")
	use("pechorin/any-jump.vim")

	-- syntax highlighting.
	use("nvim-treesitter/nvim-treesitter")
	use("nvim-treesitter/nvim-treesitter-textobjects")
	use("m-demare/hlargs.nvim")
	use({
		"folke/todo-comments.nvim",
		config = function()
			require("todo-comments").setup()
		end,
	})
	-- Debugger packages.
	use("mfussenegger/nvim-dap")
	use("leoluz/nvim-dap-go")
	use("Shatur/neovim-tasks")
	use({
		"rcarriga/nvim-dap-ui",
		config = function()
			require("dapui").setup()
		end,
	})
	use({
		"theHamsta/nvim-dap-virtual-text",
		config = function()
			require("nvim-dap-virtual-text").setup({})
		end,
	})
	use("rcarriga/cmp-dap")

	-- email integrations.
	use("https://git.sr.ht/~soywod/himalaya-vim")

	-- databases connector.
	use({
		"tpope/vim-dadbod",
		opt = true,
		requires = {
			"kristijanhusak/vim-dadbod-ui",
			"kristijanhusak/vim-dadbod-completion",
		},
		config = function()
			require("db").setup()
		end,
		cmd = { "DBUIToggle", "DBUI", "DBUIAddConnection", "DBUIFindBuffer", "DBUIRenameBuffer", "DBUILastQueryInfo" },
	})
end)

if packer_bootstrap then
	packer.sync()
end
