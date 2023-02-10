function map(mode, lhs, rhs, opts)
	local options = { noremap = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

--#region
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.termguicolors = true

require("nvim-tree").setup()
require("symbols-outline").setup()
map("n", "<space>w", ":NvimTreeToggle<CR>")
map("n", "<leader>s", ":SymbolsOutline<CR>")
--#endregion

--#region refactoring keymap
map("v", "<leader>rr", ":lua require('telescope').extensions.refactoring.refactors()<CR>")

require("crates").setup()
map("n", "<leader>ct", ":lua require('crates').toggle()<CR>", { silent = true })
map("n", "<leader>cr", ":lua require('crates').reload()<CR>", { silent = true })
map("n", "<leader>cv", ":lua require('crates').show_versions_popup()<CR>", { silent = true })
map("n", "<leader>cf", ":lua require('crates').show_features_popup()<CR>", { silent = true })
map("n", "<leader>cu", ":lua require('crates').update_crate()<CR>", { silent = true })
map("v", "<leader>cu", ":lua require('crates').update_crates()<CR>", { silent = true })
map("n", "<leader>ca", ":lua require('crates').upgrade_crate()<CR>", { silent = true })
map("v", "<leader>ca", ":lua require('crates').upgrade_crates()<CR>", { silent = true })
map("n", "<leader>cU", ":lua require('crates').update_all_crates()<CR>", { silent = true })
map("n", "<leader>cA", ":lua require('crates').upgrade_all_crates()<CR>", { silent = true })
--#endregion

-- close other buffers, except for the current.
map("n", "<leader>co", ':%bdelete|edit #|normal `"<CR>')
map("n", "<space>t", ":Lspsaga open_floaterm<CR>", { silent = true })

--#region copy to clipboard
map("v", "<leader>y", '"+y')
map("n", "<leader>Y", '"+yg_')
map("n", "<leader>y", '"+y')
map("n", "<leader>yy ", '"+yy')
--#endregion

--#region paste from clipboard
map("n", "<leader>p", '"+p')
map("n", "<leader>P", '"+P')
map("v", "<leader>p", '"+p')
map("v", "<leader>P", '"+P')
--#endregion

--#region buffer navigation
map("n", "[b", ":bprevious<CR>")
map("n", "]b", ":bnext<CR>")
map("n", "<space>b", ":Telescope buffers<CR>")
map("n", "<leader>t", ":lua require('telescope-tabs').list_tabs()<CR>")
--#endregion

--#region Lsp
map("n", "<space>s", ":Telescope lsp_document_symbols<CR>")
map("n", "<space>d", ":Telescope lsp_definitions<CR>")
map("n", "<space>i", ":Telescope lsp_implementations<CR>")
map("n", "<space>r", ":Telescope lsp_references<CR>")
map("n", "<space>k", ":Lspsaga hover_doc<CR>", { silent = true })
map("n", "<space>rn", ":Lspsaga rename<CR>", { silent = true })
map("n", "<space>f", ":Telescope find_files<CR>")
map("n", "<space>g", ":Telescope live_grep<CR>")
map("n", "<space>ca", ":Lspsaga code_action<CR>", { silent = true })
map("v", "<space>ca", ":Lspsaga code_action<CR>", { silent = true })

-- Show line diagnostics
map("n", "<leader>cd", ":Lspsaga show_line_diagnostics<CR>", { silent = true })
-- Show cursor diagnostic
map("n", "<leader>cd", ":Lspsaga show_cursor_diagnostics<CR>", { silent = true })
-- Diagnsotic jump can use `<c-o>` to jump back
map("n", "[e", ":Lspsaga diagnostic_jump_prev<CR>", { silent = true })
map("n", "]e", ":Lspsaga diagnostic_jump_next<CR>", { silent = true })
--#endregion

--#region Debuger
map("n", "<F5>", ":lua require'dap'.continue()<CR>")
map("n", "<F10>", ":lua require'dap'.step_over()<CR>")
map("n", "<F11>", ":lua require'dap'.step_into()<CR>")
map("n", "<F12>", ":lua require'dap'.step_out()<CR>")
map("n", "<leader>b", ":lua require'dap'.toggle_breakpoint()<CR>")
map("n", "<leader>B", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>")
map("n", "<leader>lp", ":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>")
map("n", "<leader>ro", ":lua require'dap'.repl.open()<CR>")
map("n", "<leader>dt", ":lua require('dap-go').debug_test()<CR>")
map("n", "<leader>dr", ":lua require('dap').run()<CR>")
map("n", "<leader>do", ":lua require('dapui').open()<CR>")
map("n", "<leader>dc", ":lua require('dapui').close()<CR>")
map("n", "<leader>ut", ":lua require('dapui').toggle()<CR>")
--#endregion
