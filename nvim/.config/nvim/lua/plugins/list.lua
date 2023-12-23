local function load_config(package)
    return function() require('plugins.' .. package) end
end

return {
    -- UI
    {
        'navarasu/onedark.nvim',
        config = load_config('ui.onedark'),
        lazy = false,
        priority = 1000,
    },
    {
        'nvim-lualine/lualine.nvim',
        config = load_config('ui.lualine'),
        event = { 'BufReadPre', 'BufNewFile' },
    },
    {
        'HiPhish/rainbow-delimiters.nvim',
        config = load_config('ui.rainbow'),
        event = { 'BufReadPre', 'BufNewFile' },
    },
    {
        'rcarriga/nvim-notify',
        config = load_config('ui.notify'),
        event = 'VeryLazy',
        cmd = 'Notifications',
    },
    {
        'stevearc/dressing.nvim',
        config = load_config('ui.dressing'),
        event = { 'BufReadPre', 'BufNewFile' },
    },
    -- Tressiter
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        dependencies = {
            'nvim-treesitter/nvim-treesitter-refactor',
            'nvim-treesitter/nvim-treesitter-textobjects',
            'RRethy/nvim-treesitter-endwise',
            'RRethy/nvim-treesitter-textsubjects',
            'windwp/nvim-ts-autotag',
        },
        config = load_config('lang.treesitter'),
        event = { 'BufReadPre', 'BufNewFile' },
    },
    -- LSP
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        dependencies = {
            'neovim/nvim-lspconfig',
            'williamboman/mason-lspconfig.nvim',
        },
        config = load_config('lang.lsp-zero'),
        event = { 'BufReadPre', 'BufNewFile' },

    },
    {
        'folke/neodev.nvim',
        ft = { 'lua', 'vim' },
        config = load_config('lang.neodev')
    },
    {
        'nvimdev/lspsaga.nvim',
        config = load_config('lang.lspsaga'),
        event = 'LspAttach',
    },
    {
        'Maan2003/lsp_lines.nvim',
        config = load_config('lang.lsp-lines'),
        event = 'LspAttach',

    },
    {
        'williamboman/mason.nvim',
        config = load_config('lang.mason'),
        cmd = 'Mason',
    },
    {
        'nvimtools/none-ls.nvim',
        dependencies = { 'neovim/nvim-lspconfig' },
        config = load_config('lang.null-ls'),
        event = { 'BufReadPre', 'BufNewFile' },
    },
    -- Completion
	{
        'hrsh7th/nvim-cmp',
        dependencies = {
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-nvim-lsp-signature-help',
            'hrsh7th/cmp-nvim-lua',
            'saadparwaiz1/cmp_luasnip',
        },
        config = load_config('lang.cmp'),
        event = 'InsertEnter',
    },
    {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        dependencies = { 'rafamadriz/friendly-snippets', },
        build = "make install_jsregexp",
        event = 'InsertEnter'
    },
    -- DAP
    -- git
    {
        'lewis6991/gitsigns.nvim',
        config = load_config('tools.gitsigns'),
        cmd = 'Gitsigns',
        event = { 'BufReadPre', 'BufNewFile' },
    },
    {
        'tpope/vim-fugitive',
        cmd = 'Git',
    },
    -- Telescope
    {
        'nvim-telescope/telescope.nvim',
        branch = '0.1.x',
        dependencies = {
            'nvim-lua/plenary.nvim',
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                build = 'make',
            },
            'nvim-telescope/telescope-symbols.nvim',
            'molecule-man/telescope-menufacture',
            'debugloop/telescope-undo.nvim',
            'ThePrimeagen/harpoon',
        },
        config = load_config('tools.telescope'),
        cmd = 'Telescope',
        keys = {
                { "<space>s", ":Telescope lsp_document_symbols<CR>" },
                { "<space>d", ":Telescope lsp_definitions<CR>" },
                { "<space>i", ":Telescope lsp_implementations<CR>" },
                { "<space>r", ":Telescope lsp_references<CR>" },
                { "<space>k", ":Lspsaga hover_doc<CR>" },
                { "<space>rn", ":Lspsaga rename<CR>" },
                { "<space>f", ":Telescope git_files<CR>" },
			    { "<space>b", ":Telescope buffers<CR>" },
                { "<space>g", ":Telescope live_grep<CR>" },
                { "<space>ca", ":Lspsaga code_action<CR>" },
                { "<space>ca", ":Lspsaga code_action<CR>" },
        },
    },
    -- tools
    {
        'nvim-tree/nvim-tree.lua',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        config = load_config('tools.nvim-tree'),
        cmd = 'NvimTreeToggle',
        keys = {
            { "<leader>w", "<cmd>NvimTreeToggle<cr>" },
        },
    },
    {
        'kylechui/nvim-surround',
        config = load_config('tools.surround'),
        keys = { 'cs', 'ds', 'ys' },
    },
    {
        'windwp/nvim-autopairs',
        config = load_config('tools.autopairs'),
        event = 'InsertEnter',
    },
}
