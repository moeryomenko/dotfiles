vim.o.shell = "fish"
vim.o.winborder = 'rounded'

-- indent
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.smarttab = true
vim.o.autoindent = true
vim.o.smartindent = true

vim.o.encoding = "utf8"

vim.o.wildmenu = true

-- splitting
vim.o.splitbelow = true
vim.o.splitright = true

-- cursor line highlight
vim.o.cursorline = true

-- sign column
vim.o.signcolumn = "yes"

-- 24-bit color
vim.o.termguicolors = true

-- netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- leader key
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- undo
vim.o.undofile = true
vim.o.undolevels = 10000
vim.o.updatetime = 200 -- Save swap file and trigger CursorHold

-- Set basic oions
vim.opt.backspace = { "indent", "eol", "start" }
vim.o.textwidth = 120
vim.o.colorcolumn = "+1"

vim.o.autocomplete = true
vim.o.signcolumn = 'yes'

--#region line number settings.
vim.o.number = true
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave", "WinEnter" }, {
	callback = function()
		vim.o.relativenumber = true
	end,
})
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertEnter", "WinLeave" }, {
	callback = function()
		vim.o.relativenumber = false
	end,
})
--#endregion

-- Filetype-specific autocommands
vim.api.nvim_create_autocmd("FileType", {
	pattern = "gitcommit",
	callback = function()
		vim.opt_local.textwidth = 72
		vim.opt_local.colorcolumn = { "+1", "51" }
		vim.opt_local.spell = true
		vim.opt_local.spelllang = "en_us"
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "yaml", "helm", "json" },
	callback = function()
		vim.bo.tabstop = 2
		vim.bo.shiftwidth = 2
		vim.bo.expandtab = true
		vim.bo.softtabstop = 2
	end,
})
