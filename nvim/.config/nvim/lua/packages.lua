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

require("packer").startup(function()
	use("wbthomason/packer.nvim")
	use("folke/tokyonight.nvim")
	use({
		"nvim-tree/nvim-tree.lua",
		requires = {
			"nvim-tree/nvim-web-devicons", -- optional, for file icons
		},
		tag = "nightly", -- optional, updated every week. (see issue #1193)
	})
	use("simrat39/symbols-outline.nvim")
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
				-- prompt for return type
				prompt_func_return_type = {
					go = true,
					cpp = true,
					c = true,
					java = true,
				},
				-- prompt for function parameters
				prompt_func_param_type = {
					go = true,
					cpp = true,
					c = true,
					java = true,
				},
			})
		end,
	})
	use("kdheepak/lazygit.nvim")
	use("tpope/vim-fugitive")
	use("yamatsum/nvim-cursorline")
	use("nvim-lua/plenary.nvim")
	use("nvim-telescope/telescope.nvim")
	use("nvim-telescope/telescope-ui-select.nvim")
	use("olacin/telescope-gitmoji.nvim")
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
	use("neovim/nvim-lspconfig")
	use("simrat39/rust-tools.nvim")
	use("saecki/crates.nvim")
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
	use("https://git.sr.ht/~p00f/clangd_extensions.nvim")
	use("mfussenegger/nvim-jdtls")
	use("scalameta/nvim-metals")
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
	use("m-demare/hlargs.nvim")
	use("nvim-treesitter/nvim-treesitter")
	use("nvim-treesitter/nvim-treesitter-textobjects")
	use({
		"folke/todo-comments.nvim",
		config = function()
			require("todo-comments").setup()
		end,
	})
	-- Debugger packages
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
			require("nvim-dap-virtual-text").setup()
		end,
	})
	use("rcarriga/cmp-dap")
	use("gelguy/wilder.nvim")
	use("https://git.sr.ht/~soywod/himalaya-vim")

	if packer_bootstrap then
		require("packer").sync()
	end
end)
