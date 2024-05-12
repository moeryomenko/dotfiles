local function map(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- close other buffers, except for the current.
map("n", "<leader>co", ':%bdelete|edit #|normal `"<CR>')

-- search modified files
map("n", "<Leader>m", ":Telescope git_status<CR>")

--#region move to window using <ctrl> hjkl keys.
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", silent = true, noremap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", silent = true, noremap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", silent = true, noremap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", silent = true, noremap = true })
--#endregion

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
map("n", "<leader>zi", ":tab split<CR>", { silent = true })
map("n", "<leader>zo", ":tab close<CR>", { silent = true })
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
