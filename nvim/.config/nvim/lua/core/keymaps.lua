local M = {}

local map = require("core.utils").map

vim.g.NetrwIsOpen = 0
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 4
vim.g.netrw_altv = 1
vim.g.netrw_winsize = 16

function ToggleNetrw()
	if vim.g.NetrwIsOpen == 1 then
		for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
			if vim.bo[bufnr].filetype == "netrw" then
				vim.api.nvim_buf_delete(bufnr, { force = true })
			end
		end
		vim.g.NetrwIsOpen = 0
	else
		vim.g.NetrwIsOpen = 1
		vim.cmd("silent Lexplore")
	end
end

vim.keymap.set("n", "<leader>w", ToggleNetrw, { silent = true })

-- close other buffers, except for the current.
map("n", "<leader>co", ':%bdelete|edit #|normal `"<CR>')

-- search modified files
map("n", "<Leader>m", ":Telescope git_status<CR>")

--#region split resize
map("n", "<A-l>", ":vert res +10<CR>", { silent = true })
map("n", "<A-h>", ":vert res -10<CR>", { silent = true })
map("n", "<A-j>", ":res -10<CR>", { silent = true })
map("n", "<A-k>", ":res +10<CR>", { silent = true })
--#endregion

--#region copy to clipboard
map("v", "<space>y", '"+y')
map("n", "<leader>Y", '"+yg_')
map("n", "<space>y", '"+y')
map("n", "<leader>yy ", '"+yy')
--#endregion

--#region
map("n", "\\zi", ":tab split<CR>", { silent = true })
map("n", "\\zo", ":tab close<CR>", { silent = true })
--#endregion

--#region paste from clipboard
map("n", "<leader>p", '"+p')
map("n", "<leader>P", '"+P')
map("v", "<leader>p", '"+p')
map("v", "<leader>P", '"+P')
--#endregion
--
--#region buffer navigation
map("n", "[b", ":bprevious<CR>")
map("n", "]b", ":bnext<CR>")
-- map("n", "<space>b", ":Telescope buffers<CR>")
-- map("n", "<leader>t", ":lua require('telescope-tabs').list_tabs()<CR>")
--#endregion

--#region text moving.
map("v", "J", ":move '>+1<CR>gv-gv")
map("v", "K", ":move '<-2<CR>gv-gv")
map("x", "J", ":move '>+1<CR>gv-gv")
map("x", "K", ":move '<-2<CR>gv-gv")
--#endregion

function M.setup_lsp_keymaps(event)
	local map = function(keys, func, desc)
		vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
	end

	local builtins = require("telescope.builtin")

	-- Jump to the definition of the word under your cursor.
	--  This is where a variable was first declared, or where a function is defined, etc.
	--  To jump back, press <C-t>.
	map("gd", builtins.lsp_definitions, "[G]oto [D]efinition")

	map("<leader>k", ":Lspsaga peek_definition<CR>", "Pee[k] definition")

	-- Find references for the word under your cursor.
	map("gr", ':lua require("telescope.builtin").lsp_references({ show_line = false })<CR>', "[G]oto [R]eferences")

	-- Jump to the implementation of the word under your cursor.
	--  Useful when your language has ways of declaring types without an actual implementation.
	map("gi", builtins.lsp_implementations, "[G]oto [I]mplementation")

	-- Fuzzy find all the symbols in your current workspace
	--  Similar to document symbols, except searches over your whole project.
	map("gs", builtins.lsp_document_symbols, "Buffer [s]ymbols (telescope)")

	-- Opens a popup that displays documentation about the word under your cursor
	--  See `:help K` for why this keymap
	map("gk", ":Lspsaga hover_doc<CR>", "Hover Documentation")

	-- Rename the variable under your cursor
	--  Most Language Servers support renaming across files, etc.
	map("grn", ":Lspsaga rename<CR>", "Code [R]e[n]ame")
	-- Execute a code action, usually your cursor needs to be on top of an error
	-- or a suggestion from your LSP for this to activate.
	map("<leader>ca", require("actions-preview").code_actions, "[C]ode [A]ction")
end

return M
