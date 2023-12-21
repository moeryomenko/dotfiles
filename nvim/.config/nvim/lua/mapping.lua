--#region
require("nvim-tree").setup()
require("symbols-outline").setup()
map("n", "<space>w", ":NvimTreeToggle<CR>")
map("n", "<leader>s", ":SymbolsOutline<CR>")
--#endregion

--#region refactoring keymap
map("v", "<leader>rr", ":lua require('telescope').extensions.refactoring.refactors()<CR>")
--#endregion

map("n", "<A-b>", "Telescope bookmarks<CR>", { silent = true })
map("n", "<space>t", ":Lspsaga open_floaterm<CR>", { silent = true })

--#region Lsp
map("n", "<space>s", ":Telescope lsp_document_symbols<CR>")
map("n", "<space>d", ":Telescope lsp_definitions<CR>")
map("n", "<space>i", ":Telescope lsp_implementations<CR>")
map("n", "<space>r", ":Telescope lsp_references<CR>")
map("n", "<space>k", ":Lspsaga hover_doc<CR>", { silent = true })
map("n", "<space>rn", ":Lspsaga rename<CR>", { silent = true })
map("n", "<space>f", ":Telescope git_files<CR>")
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

--#region Test runner
map("n", "rt", ":lua require('neotest').run.run()<CR>", { silent = true })
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
