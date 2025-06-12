return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-refactor",
		"RRethy/nvim-treesitter-endwise",
	},
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = {
				"bash",
				"c",
				"cpp",
				"go",
				"vimdoc",
				"lua",
				"json",
				"markdown",
				"yaml",
			}, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
			sync_install = false, -- install languages synchronously (only applied to `ensure_installed`)
			ignore_install = { "" }, -- List of parsers to ignore installing
			auto_install = true,
			autopairs = {
				enable = true,
			},
			endwise = {
				enable = true,
			},
			highlight = {
				enable = true, -- false will disable the whole extension
				additional_vim_regex_highlighting = false,
			},
			indent = { enable = true },
			context_commentstring = {
				enable = true,
				enable_autocmd = false,
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<c-space>",
					node_incremental = "<c-space>",
					scope_incremental = false,
					node_decremental = "<bs>",
				},
			},
			refactor = {
				highlight_definitions = {
					enable = true,
					-- Set to false if you have an `updatetime` of ~100.
					clear_on_cursor_move = true,
				},
				highlight_current_scope = { enable = false },
				smart_rename = {
					enable = true,
					keymaps = {
						smart_rename = "<leader>rr",
					},
				},
			},
		})
	end,
}
