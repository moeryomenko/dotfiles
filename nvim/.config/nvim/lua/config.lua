vim.cmd([[let g:nord_cursor_line_number_background = 1]])
vim.cmd([[let g:nord_uniform_status_lines = 1]])
vim.cmd([[let g:nord_bold_vertical_split_line = 1]])
vim.cmd([[let g:nord_uniform_diff_background = 1]])
vim.cmd([[let g:nord_bold = 1]])
vim.cmd([[let g:nord_italic = 1]])
vim.cmd([[let g:nord_italic_comments = 1]])
vim.cmd([[let g:nord_underline = 1]])

vim.cmd([[colorscheme nord]])
vim.cmd([[set shell=bash]])
vim.cmd([[set ts=4 sw=4 ai smarttab wildmenu]])
vim.cmd([[set encoding=utf8]])
vim.cmd([[set nu]])
vim.cmd([[set termguicolors cursorline]])
vim.cmd([[set background=dark]])
vim.cmd([[set backspace=indent,eol,start]])
vim.cmd([[set tw=120 cc=+1]])
vim.cmd([[au FileType gitcommit setlocal tw=72 cc=+1 cc+=51 spell spelllang=en_us]])
vim.cmd([[au FileType c,cpp setlocal tw=80 cc=+1]])
vim.cmd([[au BufNewFile,BufRead *.qml set ft=qmljs]])

vim.cmd([[let g:himalaya_folder_picker = 'telescope']])
vim.cmd([[let g:himalaya_folder_picker_telescope_preview = 1]])

require("lualine").setup({
	options = {
		theme = "auto",
	},
})
require("bufferline").setup({})

local wilder = require("wilder")
wilder.setup({ modes = { ":", "/", "?" } })
wilder.set_option(
	"renderer",
	wilder.popupmenu_renderer(wilder.popupmenu_border_theme({
		highlights = {
			border = "Normal", -- highlight to use for the border
		},
		reverse = 1,
		border = "rounded",
		left = { " ", wilder.popupmenu_devicons() },
		right = { " ", wilder.popupmenu_scrollbar() },
	}))
)
