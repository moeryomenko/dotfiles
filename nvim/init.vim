" common.
syntax on
filetype plugin indent on

set autoindent
set smarttab
set wildmenu
set encoding=utf8
set nu
set termguicolors
set cursorline
set background=dark

" search.
set incsearch
set hlsearch
set nowrapscan
set smartcase

set backspace=indent,eol,start

" needs for autoformat.
let g:python3_host_prog='/usr/bin/python'

" folder tree.
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 25

" constraint to check that the string is no more than 100 characters.
highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%101v.\+/

if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
	silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
				\ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

call plug#begin(stdpath('data') . '/plugged')

Plug 'arcticicestudio/nord-vim'
Plug 'airblade/vim-gitgutter'
Plug 'vim-airline/vim-airline'
Plug 'Chiel92/vim-autoformat'
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'
Plug 'sheerun/vim-polyglot'

call plug#end()

" styling.
colorscheme nord
let g:nord_cursor_line_number_background = 1
let g:nord_uniform_status_lines = 1
let g:nord_italic = 1
let g:nord_italic_comments = 1
let g:airline_theme='nord'
let g:airline_powerline_fonts = 1
let g:nord_uniform_status_lines = 1
set statusline+=%#warningmsg#

" code transformation.
au BufWrite * :RemoveTrailingSpaces
au BufWrite *.h,*.hpp,*.hh,*.c,*.cpp,*.cxx,*.cc,*.py,*.go,*.vim :Autoformat
noremap <F3> :Autoformat<CR>

" Use <Tab> and <S-Tab> to navigate through popup menu
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect

" Avoid showing message extra message when using completion
set shortmess+=c

" lsp keybinding and completion.
lua << EOF
local nvim_lsp = require('lspconfig')
local on_attach = function(client, bufnr)
local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

-- Mappings.
local opts = { noremap=true, silent=true }
buf_set_keymap('n', '<C-]>', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
buf_set_keymap('n', '<C-[>', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
buf_set_keymap('n', '<C-k>', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
buf_set_keymap('n', '<C-i>', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
buf_set_keymap('n', '<C-h>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
buf_set_keymap('n', '<C-r>', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

-- Set some keybinds conditional on server capabilities
if client.resolved_capabilities.document_formatting then
	buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
elseif client.resolved_capabilities.document_range_formatting then
	buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
end

-- Set autocommands conditional on server_capabilities
if client.resolved_capabilities.document_highlight then
	vim.api.nvim_exec([[
	hi LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
	hi LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
	hi LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
	augroup lsp_document_highlight
		autocmd! * <buffer>
		autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
		autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
	augroup END
	]], false)
end
end

-- Use a loop to conveniently both setup defined servers
-- and map buffer local keybindings when the language server attaches
local servers = { "gopls", "clangd", "cmake", "vimls", "terraformls" }
for _, lsp in ipairs(servers) do
	nvim_lsp[lsp].setup { on_attach = on_attach }
end
EOF

" Use completion-nvim in every buffer
autocmd BufEnter * lua require'completion'.on_attach()
