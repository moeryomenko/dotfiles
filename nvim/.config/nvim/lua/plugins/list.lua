local function load_config(package)
	return function()
		require("plugins." .. package)
	end
end

return {
	-- UI
	-- {
	-- 	"catppuccin/nvim",
	-- 	lazy = false,
	-- 	priority = 1000,
	-- 	config = load_config("ui.catppuccin"),
	-- },
	{
		"craftzdog/solarized-osaka.nvim",
		lazy = false,
		priority = 1000,
		config = load_config("ui.osaka"),
	},
	{
		"nvim-lualine/lualine.nvim",
		config = load_config("ui.lualine"),
		event = { "BufReadPre", "BufNewFile" },
	},
	{
		"HiPhish/rainbow-delimiters.nvim",
		config = load_config("ui.rainbow"),
		event = { "BufReadPre", "BufNewFile" },
	},
	{
		"rcarriga/nvim-notify",
		config = load_config("ui.notify"),
		event = "VeryLazy",
		cmd = "Notifications",
	},
	{
		"stevearc/dressing.nvim",
		config = load_config("ui.dressing"),
		event = { "BufReadPre", "BufNewFile" },
	},
	{
		"ellisonleao/glow.nvim",
		config = load_config("ui.glow"),
		cmd = "Glow",
	},
	-- Tressiter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-refactor",
			"nvim-treesitter/nvim-treesitter-textobjects",
			"RRethy/nvim-treesitter-endwise",
			"RRethy/nvim-treesitter-textsubjects",
			"windwp/nvim-ts-autotag",
			"m-demare/hlargs.nvim",
		},
		config = load_config("lang.treesitter"),
		event = { "BufReadPre", "BufNewFile" },
	},
	-- LSP
	{
		"VonHeikemen/lsp-zero.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
			"williamboman/mason-lspconfig.nvim",
		},
		config = load_config("lang.lsp-zero"),
		event = { "BufReadPre", "BufNewFile" },
	},
	{
		"folke/neodev.nvim",
		ft = { "lua", "vim" },
		config = load_config("lang.neodev"),
	},
	{
		"nvimdev/lspsaga.nvim",
		config = load_config("lang.lspsaga"),
		event = "LspAttach",
	},
	-- TODO: currently disable.
	-- {
	-- 	"Maan2003/lsp_lines.nvim",
	-- 	config = load_config("lang.lsp-lines"),
	-- 	event = "LspAttach",
	-- },
	{
		"williamboman/mason.nvim",
		config = load_config("lang.mason"),
		cmd = "Mason",
	},
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		config = load_config("lang.conform"),
		init = function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
	},
	-- Completion
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-nvim-lua",
			"saadparwaiz1/cmp_luasnip",
			"windwp/nvim-autopairs",
			"lukas-reineke/cmp-rg",
		},
		config = load_config("lang.cmp"),
		event = "InsertEnter",
	},
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		dependencies = { "rafamadriz/friendly-snippets" },
		build = "make install_jsregexp",
		event = "InsertEnter",
	},
	-- DAP
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"leoluz/nvim-dap-go",
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
			"rcarriga/cmp-dap",
			"LiadOz/nvim-dap-repl-highlights",
		},
		config = load_config("lang.dap"),
		cmd = { "DapUIToggle", "DapToggleRepl", "DapToggleBreakpoint" },
		keys = {
			{ "<F5>", ":lua require'dap'.continue()<CR>" },
			{ "<F10>", ":lua require'dap'.step_over()<CR>" },
			{ "<F11>", ":lua require'dap'.step_into()<CR>" },
			{ "<F12>", ":lua require'dap'.step_out()<CR>" },
			{ "<leader>b", ":lua require'dap'.toggle_breakpoint()<CR>" },
			{ "<leader>B", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>" },
			{ "<leader>lp", ":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>" },
			{ "<leader>ro", ":lua require'dap'.repl.open()<CR>" },
			{ "<leader>dt", ":lua require('dap-go').debug_test()<CR>" },
			{ "<leader>dr", ":lua require('dap').run()<CR>" },
			{ "<leader>do", ":DapUIToggle<CR>" },
		},
	},
	-- git
	{
		"lewis6991/gitsigns.nvim",
		config = load_config("tools.gitsigns"),
		cmd = "Gitsigns",
		event = { "BufReadPre", "BufNewFile" },
	},
	{
		"tpope/vim-fugitive",
		cmd = "Git",
	},
	{
		"rbong/vim-flog",
		cmd = { "Flog", "Flogsplit", "Floggit" },
		dependencies = {
			"tpope/vim-fugitive",
		},
	},
	-- Telescope
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
			"ThePrimeagen/refactoring.nvim",
			"nvim-telescope/telescope-symbols.nvim",
			"molecule-man/telescope-menufacture",
			"debugloop/telescope-undo.nvim",
			"ThePrimeagen/harpoon",
		},
		config = load_config("tools.telescope"),
		cmd = "Telescope",
		keys = {
			{ "gs", ":Telescope lsp_document_symbols<CR>" },
			{ "gd", ":Telescope lsp_definitions<CR>" },
			{ "gi", ":Telescope lsp_implementations<CR>" },
			{ "gr", ":Telescope lsp_references<CR>" },
			{ "gk", ":Lspsaga hover_doc<CR>" },
			{ "grn", ":Lspsaga rename<CR>" },
			{ "gf", ":Telescope git_files<CR>" },
			{ "gb", ":Telescope buffers<CR>" },
			{ "[e", ":lua vim.diagnostic.goto_prev()<CR>" },
			{ "]e", ":lua vim.diagnostic.goto_next()<CR>" },
			{ "<space>g", ":Telescope live_grep<CR>" },
			{ "<space>ca", ":Lspsaga code_action<CR>" },
			{ "<space>cd", ":Lspsaga show_line_diagnostics<CR>" },
		},
	},
	-- tools
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = load_config("tools.nvim-tree"),
		cmd = "NvimTreeToggle",
		keys = {
			{ "<space>w", "<cmd>NvimTreeToggle<cr>" },
		},
	},
	{
		"hedyhli/outline.nvim",
		config = function()
			require("outline").setup({})
		end,
		keys = {
			{ "<leader>w", "<cmd>Outline<cr>" },
		},
	},
	{
		"dhananjaylatkar/cscope_maps.nvim",
		dependencies = {
			"folke/which-key.nvim",
			"nvim-telescope/telescope.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = load_config("tools.cscope_map"),
		keys = {
			{ "<space>i", '<cmd>exe "Cscope find s" expand("<cword>")<CR><CR>' },
			{ "<space>d", '<cmd>exe "Cscope find g" expand("<cword>")<CR><CR>' },
			{ "<space>r", '<cmd>exe "Cscope find c" expand("<cword>")<CR><CR>' },
			{ "<space>f", '<cmd>exe "Cscope find f" expand("<cfile>")<CR><CR>' },
		},
	},
	{
		"kylechui/nvim-surround",
		config = load_config("tools.surround"),
		keys = { "cs", "ds", "ys" },
	},
	{
		"windwp/nvim-autopairs",
		config = load_config("tools.autopairs"),
		event = "InsertEnter",
	},
	{
		"Shatur/neovim-tasks",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = load_config("tools.tasks"),
		cmd = "Task",
	},
}
