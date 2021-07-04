" common settings {{{
syntax on
filetype plugin indent on

set shell=bash
set ai smarttab wildmenu
set encoding=utf8
set nu
set termguicolors cursorline
set background=dark
set backspace=indent,eol,start

" needs for autoformat.
let g:python3_host_prog='/usr/bin/python'

" Remember last position in file.
if has("autocmd")
	autocmd BufReadPost *
				\ if line("'\"") > 0 && line("'\"") <= line("$") |
				\   exe "normal g`\"" |
				\ endif
endif

" Constraint to check that the string is no more than 120 characters.
set tw=120 cc=+1
" Force the cursor onto a new line after 80 characters.
" However, in Git commit messages, let’s make it 72 characters.
" Colour the 81st (or 73rd) column so that we don’t type over our limit.
" In Git commit messages, also colour the 51st column (for titles).
" Enables the spell checker when editing commit messages, underlining typos and other common mistakes.
au FileType gitcommit setlocal tw=72 cc=+1 cc+=51 spell spelllang=en_us
au FileType c setlocal tw=80 cc=+1
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

" status line {{{
set noshowmode
set laststatus=2
set statusline=
set statusline+=%#TabLineSel#
set statusline+=%{(mode()=='n')?'\ \ NORMAL\ ':''}
set statusline+=%{(mode()=='i')?'\ \ INSERT\ ':''}
set statusline+=%{(mode()=='v')?'\ \ VISUAL\ ':''}
set statusline+=%{(mode()=='r')?'\ \ REPLACE\ ':''}
set statusline+=%#StatusLine#
set statusline+=%r
set statusline+=%f
set statusline+=%m
set statusline+=%=
set statusline+=%#StatusLine#
set statusline+=\ %y
set statusline+=\ %{&fileencoding?&fileencoding:&encoding}
set statusline+=\[%{&fileformat}\]
set statusline+=\ %l:%c
"}}}

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
let g:netrw_winsize = 20
"}}}

" plugins settings {{{
if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
	silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
				\ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

call plug#begin(stdpath('data') . '/plugged')

Plug 'arcticicestudio/nord-vim'
Plug 'tpope/vim-fugitive'
Plug 'Chiel92/vim-autoformat'
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'
Plug 'sheerun/vim-polyglot'
Plug 'majutsushi/tagbar'
Plug 'rust-lang/rust.vim'
Plug 'kristijanhusak/completion-tags'
Plug 'Shougo/neosnippet.vim'
Plug 'Shougo/neosnippet-snippets'
Plug 'pechorin/any-jump.vim'

call plug#end()
"}}}

" style configutations {{{
colorscheme nord
hi Normal guibg=NONE ctermbg=NONE
"}}}

" tagbar configurations {{{
let g:tagbar_width=48

" tagbar setting for golang.
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
au BufWrite *go,*.vim :Autoformat
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
" setting for anyjump.
let g:any_jump_list_numbers = 1
let g:any_jump_references_enabled = 1
let g:any_jump_grouping_enabled = 1
let g:any_jump_preview_lines_count = 5
let g:any_jump_search_prefered_engine = 'rg'
let g:any_jump_results_ui_style = 'filename_first'
let g:any_jump_window_width_ratio  = 0.6
let g:any_jump_window_height_ratio = 0.6
let g:any_jump_window_top_offset   = 4
let g:any_jump_colors = {
			\"plain_text":         "Comment",
			\"preview":            "Comment",
			\"preview_keyword":    "Operator",
			\"heading_text":       "Function",
			\"heading_keyword":    "Identifier",
			\"group_text":         "Comment",
			\"group_name":         "Function",
			\"more_button":        "Operator",
			\"more_explain":       "Comment",
			\"result_line_number": "Comment",
			\"result_text":        "Statement",
			\"result_path":        "String",
			\"help":               "Comment"
			\}
let g:any_jump_references_only_for_current_filetype = 1
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
