-- Enable LSP servers
vim.lsp.enable("luals-nvim")
vim.lsp.enable("gopls")
vim.lsp.enable("clangd")
vim.lsp.enable("neocmakelsp")
vim.lsp.enable("ty")
vim.lsp.enable("helm_ls")
vim.lsp.enable("rust-analyzer")
vim.lsp.enable("ansiblels")
vim.lsp.enable("pgtoolsls")

-- Configure diagnostics
vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "✘",
			[vim.diagnostic.severity.WARN] = "▲",
			[vim.diagnostic.severity.HINT] = "⚑",
			[vim.diagnostic.severity.INFO] = "»",
		},
	},
	virtual_lines = {
		current_line = true,
	},
	float = {
		border = "rounded",
		source = "if_many",
	},
	severity_sort = true,
})

-- Format on save autocmd
local fmt_group = vim.api.nvim_create_augroup("autoformat_cmds", { clear = true })

-- Buffer-local keymaps on LSP attach.
-- Neovim 0.12 provides these global defaults already:
--   gra (code action), gri (implementation), grn (rename), grr (references),
--   grt (type definition), grx (codelens), gO (document symbols), K (hover)
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(event)
		local client_id = vim.tbl_get(event, "data", "client_id")
		local client = vim.lsp.get_client_by_id(client_id)
		local bufnr = event.buf

		if client and client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client_id, bufnr, { autotrigger = true })
		end

		local function bufmap(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
		end

		bufmap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", "Go to definition")
		bufmap("n", "gq", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", "Format buffer")

		bufmap("n", "[e", "<cmd>lua vim.diagnostic.goto_prev()<cr>", "Previous diagnostic")
		bufmap("n", "]e", "<cmd>lua vim.diagnostic.goto_next()<cr>", "Next diagnostic")
		bufmap("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<cr>", "Show diagnostics")
		bufmap("n", "<leader>q", "<cmd>lua vim.diagnostic.setloclist()<cr>", "Diagnostics loclist")

		if not client or not client:supports_method("textDocument/formatting") then
			return
		end

		vim.api.nvim_clear_autocmds({ group = fmt_group, buffer = event.buf })

		vim.api.nvim_create_autocmd("BufWritePre", {
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
	end,
})
