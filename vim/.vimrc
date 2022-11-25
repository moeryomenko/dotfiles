" Plugins {{{
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/0.10.0/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

Plug 'arcticicestudio/nord-vim'
Plug 'tpope/vim-fugitive'
Plug 'joe-skb7/cscope-maps'
Plug 'majutsushi/tagbar'

call plug#end()
" }}}

" Basic configuration {{{

" file type configurations {{{
" Disable compatibility with vi which can cause unexpected issues.
set nocompatible
" Enable type file detection. Vim will be able to try to detect the type of file in use.
filetype on
" Enable plugins and load plugin for the detected file type.
filetype plugin on
" Load an indent file for the detected file type.
filetype indent on
" Turn syntax highlighting on.
syntax on

au FileType gitcommit setlocal tw=72 cc=+1 cc+=51 spell spelllang=en_us
au FileType c,cpp setlocal tw=80 cc=+1
"}}}

" navigation configuration {{{
" Add numbers to each line on the left-hand side.
set nu rnu
" Highlight cursor line underneath the cursor horizontally.
set cursorline
" }}}

" tab confirations {{{
" Set shift width to 4 spaces.
set shiftwidth=8
" Set tab width to 4 columns.
set tabstop=8
" Use space characters instead of tabs.
set expandtab
" }}}

" Do not save backup files.
set nobackup
" Do not let cursor scroll below or above N number of lines when scrolling.
set scrolloff=10
" Do not wrap lines. Allow long lines to extend as far as the line goes.
set nowrap

" search configuration {{{
" While searching though a file incrementally highlight matching characters as you type.
set incsearch
" Ignore capital letters during search.
set ignorecase
" Override the ignorecase option if searching for capital letters.
" This will allow you to search specifically for capital letters.
set smartcase
" Show partial command you type in the last line of the screen.
set showcmd
" Show the mode you are on the last line.
set showmode
" Show matching words during a search.
set showmatch
" Use highlighting when doing a search.
set hlsearch
" }}}

" Set the commands to save in history default number is 20.
set history=1000

" wildmenu configurations {{{
" Enable auto completion menu after pressing TAB.
set wildmenu
" Make wildmenu behave like similar to Bash completion.
set wildmode=list:longest
" }}}

" status line configurations {{{
set laststatus=2
set statusline=%<%f%h%m%r%=format=%{&fileformat}\ file=%{&fileencoding}\ enc=%{&encoding}\ %b\ 0x%B\ %l,%c%V\ %P
set ruler
set showcmd
set showmode
" }}}

" colorscheme configurations {{{
let g:nord_cursor_line_number_background = 1
let g:nord_uniform_status_lines = 1
let g:nord_bold_vertical_split_line = 1
let g:nord_uniform_diff_background = 1
let g:nord_bold = 1
let g:nord_italic = 1
let g:nord_italic_comments = 1
let g:nord_underline = 1
colorscheme nord
" }}}

" trailing space configurations {{{
" Highlight trailing spaces
" http://vim.wikia.com/wiki/Highlight_unwanted_spaces
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()
" }}}

" folding configations {{{
" This will enable code folding.
" Use the marker method of folding.
augroup filetype_vim
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END
" }}}

" }}}

" mapping configurations {{{
let mapleader ="\<Space>"
nmap <leader>t :TagbarToggle<CR>

" cscope mapping {{{
nmap <silent> <leader>i :cs find s <C-R>=expand("<cword>")<CR><CR>
nmap <silent> <leader>d :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <silent> <leader>r :cs find c <C-R>=expand("<cword>")<CR><CR>
nmap <silent> <leader>s :cs find t struct <C-R>=expand("<cword>")<CR> {<CR>
nmap <silent> <leader>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
" }}}

" }}}

" file explorer configuraitons {{{
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 16

" toggle configuration {{{
let g:NetrwIsOpen=0

function! ToggleNetrw()
    if g:NetrwIsOpen
        let i = bufnr("$")
        while (i >= 1)
            if (getbufvar(i, "&filetype") == "netrw")
                silent exe "bwipeout " . i 
            endif
            let i-=1
        endwhile
        let g:NetrwIsOpen=0
    else
        let g:NetrwIsOpen=1
        silent Lexplore
    endif
endfunction

nmap <silent> <leader>w :call ToggleNetrw()<CR>
" }}}

" }}}
