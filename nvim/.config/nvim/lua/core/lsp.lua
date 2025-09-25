-- Enable LSP servers
vim.lsp.enable('luals-nvim')
vim.lsp.enable('gopls')
vim.lsp.enable('clangd')
-- vim.lsp.enable('pylyzer')
-- vim.lsp.enable('ansiblels')
-- vim.lsp.enable('neocmakelsp')
-- vim.lsp.enable('pgtoolsls')
-- vim.lsp.enable('helm_ls')

-- Configure diagnostics
vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = '✘',
			[vim.diagnostic.severity.WARN] = '▲',
			[vim.diagnostic.severity.HINT] = '⚑',
			[vim.diagnostic.severity.INFO] = '»',
		},
	},
	virtual_text = { current_line = true },
	float = {
		border = 'rounded',
		source = 'if_many',
	},
	severity_sort = true,
})

-- Set sign column to always show
vim.o.signcolumn = 'yes'

-- Set up completion and keymaps on LSP attach
vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(event)
		local client_id = vim.tbl_get(event, 'data', 'client_id')
		local client = vim.lsp.get_client_by_id(client_id)
		local bufnr = event.buf

		-- Enable builtin auto-completion
		if client and client:supports_method('textDocument/completion') then
			vim.lsp.completion.enable(true, client_id, bufnr, { autotrigger = true })
		end

		-- Set completion options
		vim.opt_local.completeopt = { 'menu', 'menuone', 'noselect' }

		-- Tab navigation for completion suggestions
		vim.keymap.set('i', '<Tab>', function()
			if vim.fn.pumvisible() == 1 then
				return '<C-n>'
			else
				return '<Tab>'
			end
		end, { expr = true, buffer = bufnr })

		vim.keymap.set('i', '<S-Tab>', function()
			if vim.fn.pumvisible() == 1 then
				return '<C-p>'
			else
				return '<S-Tab>'
			end
		end, { expr = true, buffer = bufnr })

		local function bufmap(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
		end

		-- Core navigation keymaps (using modern Neovim 0.11 defaults)
		bufmap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', 'Go to definition')
		-- K mapping for hover is now built-in by default in 0.11, with improved markdown rendering
		bufmap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', 'Show hover')
		bufmap('n', 'grr', '<cmd>lua vim.lsp.buf.references()<cr>', 'Show references')
		bufmap('n', 'gri', '<cmd>lua vim.lsp.buf.implementation()<cr>', 'Show implementations')

		-- Actions (using modern 0.11 keybind conventions)
		bufmap('n', 'grn', '<cmd>lua vim.lsp.buf.rename()<cr>', 'Rename symbol')
		bufmap('n', 'gra', '<cmd>lua vim.lsp.buf.code_action()<cr>', 'Code action')
		bufmap('n', 'gq', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', 'Format buffer')

		-- Diagnostics navigation
		bufmap('n', '[e', '<cmd>lua vim.diagnostic.goto_prev()<cr>', 'Previous diagnostic')
		bufmap('n', ']e', '<cmd>lua vim.diagnostic.goto_next()<cr>', 'Next diagnostic')
		bufmap('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<cr>', 'Show diagnostics')
		bufmap('n', '<leader>q', '<cmd>lua vim.diagnostic.setloclist()<cr>', 'Diagnostics loclist')
	end
})

-- Format on save autocmd
local fmt_group = vim.api.nvim_create_augroup('autoformat_cmds', { clear = true })

local function setup_autoformat(event)
	local id = vim.tbl_get(event, 'data', 'client_id')
	local client = id and vim.lsp.get_client_by_id(id)
	if client == nil then return end

	-- Only set up autoformat for clients that support formatting
	if not client.supports_method('textDocument/formatting') then
		return
	end

	vim.api.nvim_clear_autocmds({ group = fmt_group, buffer = event.buf })

	vim.api.nvim_create_autocmd('BufWritePre', {
		buffer = event.buf,
		group = fmt_group,
		callback = function(e)
			vim.lsp.buf.format({
				bufnr = e.buf,
				async = false,
				timeout_ms = 10000,
			})
		end,
	})
end

vim.api.nvim_create_autocmd('LspAttach', {
	callback = setup_autoformat,
})
