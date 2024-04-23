" Plugins {{{
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/0.10.0/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-fugitive'
Plug 'rbong/vim-flog'
Plug 'rhysd/committia.vim'
Plug 'joe-skb7/cscope-maps'
Plug 'bfrg/vim-cpp-modern'
Plug 'cdelledonne/vim-cmake'
Plug 'rust-lang/rust.vim'
Plug 'majutsushi/tagbar'
Plug 'ghifarit53/tokyonight-vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" lsp plugins {{{
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
" }}}

Plug 'tikhomirov/vim-glsl'

call plug#end()
" }}}

" Basic configuration {{{

" Disable compatibility with vi which can cause unexpected issues.
set nocompatible
set history=500
set so=7
set wrap

let g:airline#extensions#tabline#enabled = 1

" backup configuration {{{
set nobackup
set nowb
set noswapfile
" }}}

" file type configurations {{{
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
set nu

augroup numbertoggle
        autocmd!
        autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu   | endif
        autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nornu | endif
augroup END


" Highlight cursor line underneath the cursor horizontally.
set cursorline
" }}}

" tab confirations {{{
" Set shift width to 8 spaces.
set shiftwidth=8
" Set tab width to 8 columns.
set tabstop=8
" Use space characters instead of tabs.
set expandtab
set smarttab
set ai
" }}}

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

nnoremap <silent>rg :Rg<CR>
" }}}

" wildmenu configurations {{{
" Enable auto completion menu after pressing TAB.
set wildmenu
" Make wildmenu behave like similar to Bash completion.
set wildmode=list:longest
" Ignore compiled files
set wildignore=*.o,*~,*.pyc
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
" }}}

" colorscheme settings {{{
if !has('gui_running') && &term =~ '^\%(screen\|tmux\)'
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif
set termguicolors
set background=dark
let g:tokyonight_style = 'storm'
let g:tokyonight_enable_italic = 1
colorscheme tokyonight
" }}}

" c/c++ highlight {{{
" Enable function highlighting
let g:cpp_function_highlight = 1
" Enable highlighting of C++11 attributes
let g:cpp_attributes_highlight = 1
" Highlight struct/class member variables (affects both C and C++ files)
let g:cpp_member_highlight = 1
" }}}

" glsl highlight {{{
autocmd! BufNewFile,BufRead *.vs,*.fs,*.tess,*.tesc,*.comp,*.vert,*.frag,*.glsl,*.mesh set ft=glsl
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
autocmd BufWritePre * :%s/\s\+$//e
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
" tagbar
nmap <silent> <leader>t :TagbarToggle<CR>

" Source Vim configuration file and install plugins
nnoremap <silent><leader>1 :source ~/.vimrc \| :PlugInstall<CR>

" search selected pattern {{{
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>
" }}}

" clipboard {{{
vnoremap <silent> <leader>y ""y:call system("wl-copy", @")<CR>
" }}}

" buffers navigation {{{
nmap <silent><leader>bn :bnext<CR>
nmap <silent><leader>bp :bprevious<CR>
nnoremap <silent>gb :Buffers<CR>
" }}}

" cscope mapping {{{
nmap <silent> <leader>i :cs find s <C-R>=expand("<cword>")<CR><CR>
nmap <silent> <leader>d :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <silent> <leader>r :cs find c <C-R>=expand("<cword>")<CR><CR>
nmap <silent> <leader>s :cs find t struct <C-R>=expand("<cword>")<CR> {<CR>
nmap <silent> <leader>c :cs find t class <C-R>=expand("<cword>")<CR><CR>
nmap <silent> <leader>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
" }}}

" lsp mapping  {{{
nmap <silent> gd :LspDefinition<CR>
nmap <silent> gi :LspImplementation<CR>
nmap <silent> th :LspHover<CR>
nmap <silent> gr :LspReferences<CR>
" }}}

" split mapping {{{
nmap <silent><c-l> <c-w>l
nmap <silent><c-h> <c-w>h
nmap <silent><c-j> <c-w>j
nmap <silent><c-k> <c-w>k

nmap <silent>`l :vert res +10<CR>
nmap <silent>`h :vert res -10<CR>
nmap <silent>`j :res -10<CR>
nmap <silent>`k :res +10<CR>
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

" netrw mapping {{{
function! NetrwMapping()
        nmap <buffer> H u
        nmap <buffer> h -^
        nmap <buffer> l <CR>

        nmap <buffer> . gh
        nmap <buffer> P <C-w>z

        nmap <buffer> L <CR>:Lexplore<CR>
        nmap <buffer> ff %:w<CR>:buffer #<CR>

        nmap <buffer> fl :echo join(netrw#Expose("netrwmarkfilelist"), "\n")<CR>
endfunction

augroup netrw_mapping
  autocmd!
  autocmd filetype netrw call NetrwMapping()
augroup END
" }}}

nnoremap <silent>gf :GFiles<CR>

" }}}

" cmake configuration {{{
let g:cmake_build_dir_location = 'build'
let g:cmake_generate_options = [
                        \ '-GNinja',
                        \ '-DEXE_LINKER_FLAGS_INIT="-fuse-ld=mold"',
                        \ '-DSHARED_LINKER_FLAGS_INIT="-fuse-ld=mold"',
                        \ '-DCMAKE_C_COMPILER=clang',
                        \ '-DCMAKE_CXX_COMPILER=clang++',
                        \ '-DC_COMPILER_LAUNCHER="/usr/bin/ccache"',
                        \ '-DCXX_COMPILER_LAUNCHER="/usr/bin/ccache"']
let g:cmake_link_compile_commands = 1
let g:cmake_statusline = 1
" }}}

" sessions {{{
fu! SaveSess()
    execute 'mksession!'
endfunction

fu! RestoreSess()
if filereadable(getcwd() . '/Session.vim')
        execute 'so ' . getcwd() . '/Session.vim'
endif
endfunction

command SaveSession :call SaveSess()
command RestoreSession :call RestoreSess()

" }}}
