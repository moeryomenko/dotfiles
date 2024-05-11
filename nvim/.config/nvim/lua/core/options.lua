vim.opt.shell = "bash"

-- indent
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.smarttab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.encoding = "utf8"

vim.opt.wildmenu = true

-- splitting
vim.opt.splitbelow = true
vim.opt.splitright = true

-- cursor line highlight
vim.opt.cursorline = true

-- sign column
vim.opt.signcolumn = "yes"

-- 24-bit color
vim.opt.termguicolors = true

-- netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- skip startup screen
vim.opt.shortmess:append("I")

-- leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- undo
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.updatetime = 200 -- Save swap file and trigger CursorHold

vim.cmd([[
          set backspace=indent,eol,start
          set tw=120 cc=+1
          au FileType gitcommit setlocal tw=72 cc=+1 cc+=51 spell spelllang=en_us
          au FileType c,cpp setlocal tw=80 cc=+1
]])

--#region line number settings.
vim.opt.number = true
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave", "WinEnter" }, {
	callback = function()
		vim.opt.relativenumber = true
	end,
})
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertEnter", "WinLeave" }, {
	callback = function()
		vim.opt.relativenumber = false
	end,
})
--#endregion
