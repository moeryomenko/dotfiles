" Forest Blue colorscheme for Vim
" Inspired by mystical blue forest with snow-covered ground

" Reset highlights
highlight clear
if exists("syntax_on")
  syntax reset
endif

set termguicolors
let g:colors_name = "forest_blue"

" Color palette from the mystical blue forest image
" Core backgrounds
let s:bg = "#0d1429"
let s:bg_alt = "#111a33"
let s:bg_light = "#16213d"
let s:bg_lighter = "#1c2847"

" Special backgrounds
let s:bg_statusline = "#0a1020"
let s:bg_float = "#0f1830"

" Foreground colors
let s:fg = "#6ecfff"
let s:fg_alt = "#5c7db8"
let s:fg_dark = "#2d4a7a"
let s:fg_light = "#8da8e8"

" Primary syntax colors
let s:blue = "#4a73bf"
let s:light_blue = "#5c85d9"
let s:dark_blue = "#2d4a80"
let s:cyan = "#4d7aa6"

" Complementary syntax colors
let s:purple = "#6b5cbf"
let s:green = "#5ca673"
let s:yellow = "#7dcfff"
let s:orange = "#5dcfff"
let s:red = "#5aafff"

" UI element colors
let s:gray = "#3d4d73"
let s:gray_light = "#4d5d8a"
let s:gray_dark = "#2d3d5c"

" Helper function to set highlights
function! s:hi(group, fg, bg, style, sp)
  let l:cmd = "highlight " . a:group
  if a:fg != ""
    let l:cmd = l:cmd . " guifg=" . a:fg
  endif
  if a:bg != ""
    let l:cmd = l:cmd . " guibg=" . a:bg
  endif
  if a:style != ""
    let l:cmd = l:cmd . " gui=" . a:style
  endif
  if a:sp != ""
    let l:cmd = l:cmd . " guisp=" . a:sp
  endif
  execute l:cmd
endfunction

" Editor highlights
call s:hi("Normal", s:fg, s:bg, "", "")
call s:hi("NormalFloat", s:fg, s:bg_float, "", "")
call s:hi("NormalNC", s:fg_alt, s:bg, "", "")

" Cursor and selection
call s:hi("Cursor", s:bg, s:light_blue, "", "")
call s:hi("CursorLine", "", s:bg_light, "", "")
call s:hi("CursorColumn", "", s:bg_lighter, "", "")
call s:hi("ColorColumn", "", s:bg_lighter, "", "")
call s:hi("Visual", "", s:dark_blue, "", "")
call s:hi("VisualNOS", "", s:dark_blue, "", "")

" Line numbers
call s:hi("LineNr", s:gray, "", "", "")
call s:hi("CursorLineNr", s:light_blue, "", "bold", "")
call s:hi("SignColumn", s:gray, s:bg, "", "")

" Search and matching
call s:hi("Search", s:bg, s:yellow, "", "")
call s:hi("IncSearch", s:bg, s:orange, "", "")
call s:hi("MatchParen", s:light_blue, "", "bold", "")

" Splits and windows
call s:hi("VertSplit", s:gray_dark, s:bg, "", "")
call s:hi("WinSeparator", s:gray_dark, s:bg, "", "")
call s:hi("StatusLine", s:fg, s:bg_light, "", "")
call s:hi("StatusLineNC", s:fg_dark, s:bg_statusline, "", "")

" Tabs
call s:hi("TabLine", s:fg_dark, s:bg_light, "", "")
call s:hi("TabLineSel", s:fg_light, s:blue, "", "")
call s:hi("TabLineFill", "", s:bg_light, "", "")

" Popup menu
call s:hi("Pmenu", s:fg, s:bg_alt, "", "")
call s:hi("PmenuSel", s:fg_light, s:dark_blue, "", "")
call s:hi("PmenuSbar", "", s:gray_dark, "", "")
call s:hi("PmenuThumb", "", s:gray, "", "")

" Messages and command line
call s:hi("ModeMsg", s:light_blue, "", "bold", "")
call s:hi("MoreMsg", s:green, "", "bold", "")
call s:hi("ErrorMsg", s:red, "", "bold", "")
call s:hi("WarningMsg", s:yellow, "", "bold", "")

" Folds
call s:hi("Folded", s:fg_dark, s:bg_light, "", "")
call s:hi("FoldColumn", s:gray, s:bg, "", "")

" Diffs
call s:hi("DiffAdd", s:green, s:bg, "", "")
call s:hi("DiffChange", s:yellow, s:bg, "", "")
call s:hi("DiffDelete", s:red, s:bg, "", "")
call s:hi("DiffText", s:yellow, s:gray_dark, "", "")

" Spelling
call s:hi("SpellBad", "", "", "undercurl", s:red)
call s:hi("SpellCap", "", "", "undercurl", s:blue)
call s:hi("SpellLocal", "", "", "undercurl", s:cyan)
call s:hi("SpellRare", "", "", "undercurl", s:purple)

" Miscellaneous
call s:hi("Directory", s:blue, "", "", "")
call s:hi("Title", s:light_blue, "", "bold", "")
call s:hi("Question", s:green, "", "", "")
call s:hi("NonText", s:gray, "", "", "")
call s:hi("SpecialKey", s:gray, "", "", "")
call s:hi("Whitespace", s:gray_dark, "", "", "")

" Syntax highlighting
call s:hi("Comment", s:gray, "", "italic", "")
call s:hi("Constant", s:cyan, "", "", "")
call s:hi("String", s:green, "", "", "")
call s:hi("Character", s:orange, "", "", "")
call s:hi("Number", s:yellow, "", "", "")
call s:hi("Boolean", s:yellow, "", "", "")
call s:hi("Float", s:yellow, "", "", "")

call s:hi("Identifier", s:light_blue, "", "", "")
call s:hi("Function", s:blue, "", "bold", "")

call s:hi("Statement", s:purple, "", "bold", "")
call s:hi("Conditional", s:purple, "", "", "")
call s:hi("Repeat", s:purple, "", "", "")
call s:hi("Label", s:purple, "", "", "")
call s:hi("Operator", s:fg, "", "", "")
call s:hi("Keyword", s:purple, "", "", "")
call s:hi("Exception", s:red, "", "", "")

call s:hi("PreProc", s:yellow, "", "", "")
call s:hi("Include", s:purple, "", "", "")
call s:hi("Define", s:purple, "", "", "")
call s:hi("Macro", s:red, "", "", "")
call s:hi("PreCondit", s:yellow, "", "", "")

call s:hi("Type", s:light_blue, "", "", "")
call s:hi("StorageClass", s:light_blue, "", "", "")
call s:hi("Structure", s:light_blue, "", "", "")
call s:hi("Typedef", s:light_blue, "", "", "")

call s:hi("Special", s:orange, "", "", "")
call s:hi("SpecialChar", s:orange, "", "", "")
call s:hi("Tag", s:red, "", "", "")
call s:hi("Delimiter", s:fg_alt, "", "", "")
call s:hi("SpecialComment", s:gray, "", "", "")
call s:hi("Debug", s:red, "", "", "")

call s:hi("Underlined", "", "", "underline", "")
call s:hi("Ignore", s:gray, "", "", "")
call s:hi("Error", s:red, "", "bold", "")
call s:hi("Todo", s:yellow, s:bg, "bold", "")

" LSP/Diagnostics (for Vim 8.2+)
call s:hi("DiagnosticError", s:red, "", "", "")
call s:hi("DiagnosticWarn", s:yellow, "", "", "")
call s:hi("DiagnosticInfo", s:blue, "", "", "")
call s:hi("DiagnosticHint", s:cyan, "", "", "")

call s:hi("DiagnosticUnderlineError", "", "", "undercurl", s:red)
call s:hi("DiagnosticUnderlineWarn", "", "", "undercurl", s:yellow)
call s:hi("DiagnosticUnderlineInfo", "", "", "undercurl", s:blue)
call s:hi("DiagnosticUnderlineHint", "", "", "undercurl", s:cyan)

" Git signs (for vim-gitgutter, vim-signify, etc.)
call s:hi("GitSignsAdd", s:green, "", "", "")
call s:hi("GitSignsChange", s:yellow, "", "", "")
call s:hi("GitSignsDelete", s:red, "", "", "")
call s:hi("SignifySignAdd", s:green, "", "", "")
call s:hi("SignifySignChange", s:yellow, "", "", "")
call s:hi("SignifySignDelete", s:red, "", "", "")

" Airline
call s:hi("airline_c", s:fg, s:bg_light, "", "")

" FZF
call s:hi("fzf1", s:fg, s:bg_float, "", "")
call s:hi("fzf2", s:fg, s:bg_float, "", "")
call s:hi("fzf3", s:fg, s:bg_float, "", "")

" NERDTree/netrw
call s:hi("Directory", s:blue, "", "", "")
call s:hi("netrwDir", s:blue, "", "", "")
call s:hi("netrwClassify", s:blue, "", "", "")
call s:hi("netrwLink", s:cyan, "", "", "")
call s:hi("netrwSymLink", s:cyan, "", "", "")
call s:hi("netrwExe", s:green, "", "", "")

" Tagbar
call s:hi("TagbarSignature", s:green, "", "", "")

" Markdown highlights
call s:hi("markdownCode", s:green, s:bg_lighter, "", "")
call s:hi("markdownCodeBlock", s:fg_alt, s:bg_lighter, "", "")
call s:hi("markdownCodeDelimiter", s:gray, s:bg_lighter, "", "")
call s:hi("markdownH1", s:light_blue, "", "bold", "")
call s:hi("markdownH2", s:light_blue, "", "bold", "")
call s:hi("markdownH3", s:blue, "", "bold", "")
call s:hi("markdownH4", s:blue, "", "", "")
call s:hi("markdownH5", s:blue, "", "", "")
call s:hi("markdownH6", s:blue, "", "", "")
call s:hi("markdownHeadingDelimiter", s:light_blue, "", "bold", "")
call s:hi("markdownHeadingRule", s:light_blue, "", "bold", "")
call s:hi("markdownBold", s:fg_light, "", "bold", "")
call s:hi("markdownItalic", s:fg_light, "", "italic", "")
call s:hi("markdownBoldItalic", s:fg_light, "", "bold,italic", "")
call s:hi("markdownUrl", s:cyan, "", "underline", "")
call s:hi("markdownLink", s:light_blue, "", "", "")
call s:hi("markdownLinkText", s:light_blue, "", "", "")
call s:hi("markdownLinkDelimiter", s:gray, "", "", "")
call s:hi("markdownLinkTextDelimiter", s:gray, "", "", "")
call s:hi("markdownListMarker", s:purple, "", "", "")
call s:hi("markdownOrderedListMarker", s:purple, "", "", "")
call s:hi("markdownRule", s:gray, "", "", "")
call s:hi("markdownBlockquote", s:gray, "", "italic", "")

" HTML highlights
call s:hi("htmlH1", s:light_blue, "", "bold", "")
call s:hi("htmlH2", s:light_blue, "", "bold", "")
call s:hi("htmlH3", s:blue, "", "bold", "")
call s:hi("htmlH4", s:blue, "", "", "")
call s:hi("htmlH5", s:blue, "", "", "")
call s:hi("htmlH6", s:blue, "", "", "")

" C/C++ highlights
call s:hi("cInclude", s:purple, "", "", "")
call s:hi("cDefine", s:purple, "", "", "")
call s:hi("cPreCondit", s:yellow, "", "", "")
call s:hi("cType", s:light_blue, "", "", "")
call s:hi("cStorageClass", s:purple, "", "", "")
call s:hi("cppStructure", s:light_blue, "", "", "")

" Rust highlights
call s:hi("rustKeyword", s:purple, "", "", "")
call s:hi("rustModPath", s:light_blue, "", "", "")
call s:hi("rustMacro", s:red, "", "", "")
call s:hi("rustFuncCall", s:blue, "", "", "")
