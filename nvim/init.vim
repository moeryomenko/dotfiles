" common settings {{{
syntax on
filetype plugin indent on

set ai smarttab wildmenu
set encoding=utf8
set nu rnu
set termguicolors cursorline
set background=dark

" Remember last position in file
if has("autocmd")
	autocmd BufReadPost *
				\ if line("'\"") > 0 && line("'\"") <= line("$") |
				\   exe "normal g`\"" |
				\ endif
endif
"}}}

" folding configurations {{{
set foldmethod=syntax
autocmd FileType vim setlocal foldmethod=marker
"}}}

" search configurations {{{
set incsearch
set hlsearch
set nowrapscan
set smartcase
"}}}

set backspace=indent,eol,start

" needs for autoformat.
let g:python3_host_prog='/usr/bin/python'

" folder tree {{{
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_fastbrowse = 2
let g:netrw_keepdir = 0
let g:netrw_retmap = 1
let g:netrw_silent = 1
let g:netrw_special_syntax = 1
let g:netrw_winsize = 25
"}}}

" plugins settings {{{
if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
	silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
				\ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

call plug#begin(stdpath('data') . '/plugged')

Plug 'arcticicestudio/nord-vim'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'vim-airline/vim-airline'
Plug 'Chiel92/vim-autoformat'
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'
Plug 'sheerun/vim-polyglot'
Plug 'majutsushi/tagbar'
Plug 'rust-lang/rust.vim'
Plug 'rhysd/git-messenger.vim'
Plug 'kristijanhusak/completion-tags'
Plug 'Shougo/neosnippet.vim'
Plug 'Shougo/neosnippet-snippets'

call plug#end()
"}}}

" git configurations {{{
" view git messege and diff by <Leader>gm.
let g:git_messenger_always_into_popup = 1
let g:git_messenger_include_diff = 1
hi gitmessengerPopupNormal term=None guifg=#eeeeee guibg=#333333 ctermfg=255 ctermbg=234
hi gitmessengerHeader term=None guifg=#88b8f6 ctermfg=111
hi gitmessengerHash term=None guifg=#f0eaaa ctermfg=229
hi gitmessengerHistory term=None guifg=#fd8489 ctermfg=210
" Force the cursor onto a new line after 80 characters
" However, in Git commit messages, let’s make it 72 characters
" Colour the 81st (or 73rd) column so that we don’t type over our limit
" In Git commit messages, also colour the 51st column (for titles)
" enables the spell checker when editing commit messages, underlining typos
" and other common mistakes.
au FileType gitcommit setlocal tw=80 tw=72 cc=+1 cc+=51 spell spelllang=en_us
" }}}

" style configutations {{{
colorscheme nord
let g:nord_cursor_line_number_background = 1
let g:nord_uniform_status_lines = 1
let g:nord_italic = 1
let g:nord_italic_comments = 1
let g:airline_theme='nord'
let g:airline_powerline_fonts = 1
let g:nord_uniform_status_lines = 1
set statusline+=%#warningmsg#
"}}}

" tagbar configurations {{{
let g:tagbar_width=48

" tagbar setting for golang
let g:tagbar_type_go = {
			\ 'ctagstype' : 'go',
			\ 'kinds'     : [
			\ 'p:package',
			\ 'i:imports:1',
			\ 'c:constants',
			\ 'v:variables',
			\ 't:types',
			\ 'n:interfaces',
			\ 'w:fields',
			\ 'e:embedded',
			\ 'm:methods',
			\ 'r:constructor',
			\ 'f:functions'
			\ ],
			\ 'sro' : '.',
			\ 'kind2scope' : {
			\ 't' : 'ctype',
			\ 'n' : 'ntype'
			\ },
			\ 'scope2kind' : {
			\ 'ctype' : 't',
			\ 'ntype' : 'n'
			\ },
			\ 'ctagsbin'  : 'gotags',
			\ 'ctagsargs' : '-sort -silent'
			\ }

nmap <F8> :TagbarToggle<CR>
"}}}

" code transformation {{{
au BufWrite * :RemoveTrailingSpaces
au BufWrite *.h,*.hpp,*.hh,*.c,*.cpp,*.cxx,*.cc,*.py,*.go,*.vim :Autoformat
noremap <F3> :Autoformat<CR>
"}}}

" lsp config {{{
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
local servers = { "gopls", "clangd", "cmake", "vimls", "rust_analyzer" }
for _, lsp in ipairs(servers) do
	nvim_lsp[lsp].setup { on_attach = on_attach }
end
EOF
"}}}

" completion configurations {{{
" Use completion-nvim in every buffer.
autocmd BufEnter * lua require'completion'.on_attach()
" Set completeopt to have a better completion experience.
set completeopt=menuone,noinsert,noselect
" Avoid showing message extra message when using completion.
set shortmess+=c
" Enable neosnippet for completion.
let g:completion_enable_snippet = "Neosnippet"
let g:neosnippet#snippets_directory = "~/.config/nvim/snippets"
" combine tags, snippets with lsp.
let g:completion_chain_complete_list = {
			\ 'default': [
			\    {'complete_items': ['lsp', 'tags', 'snippet']},
			\  ]}
" Use <Tab> and <S-Tab> to navigate through popup menu.
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" Plugin key-mappings.
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)
"}}}

" constraint to check that the string is no more than 120 characters.
highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%121v.\+/
set cc=121
