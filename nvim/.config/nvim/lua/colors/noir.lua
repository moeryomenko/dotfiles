-- Neovim default colorscheme (dark)
-- Recreates the compiled-in C defaults from src/nvim/highlight_group.c
-- highlight_init_both[]  (lines 145-357) + highlight_init_dark[]  (lines 444-525)

local M = {}

-- Neovim default named color palette (highlight_group.c:2947-2974)
local colors = {
	-- Core backgrounds
	bg = "#14161b",      -- NvimDarkGrey2
	bg_alt = "#07080d",  -- NvimDarkGrey1 (floats, folded bg)
	bg_light = "#2c2e33", -- NvimDarkGrey3 (cursor line, pmenu)
	bg_lighter = "#4f5258", -- NvimDarkGrey4 (visual, matchparen)

	-- Special backgrounds
	bg_statusline = "#4f5258", -- NvimDarkGrey4 (statusline bg)
	bg_float = "#07080d",   -- NvimDarkGrey1 (normal float)

	-- Foreground
	fg = "#e0e2ea",    -- NvimLightGrey2 (Normal text)
	fg_alt = "#9b9ea4", -- NvimLightGrey4 (comments, folded fg)
	fg_dark = "#4f5258", -- NvimDarkGrey4 (line numbers, nontext)
	fg_light = "#eef1f8", -- NvimLightGrey1 (search, diff fg)

	-- Syntax colors
	cyan = "#8cf8f7", -- NvimLightCyan (Function, Special, Directory)
	blue = "#a6dbff", -- NvimLightBlue (Identifier, DiagnosticHint)
	green = "#b3f6c0", -- NvimLightGreen (String, ModeMsg)
	yellow = "#fce094", -- NvimLightYellow (WarningMsg, CurSearch bg)
	red = "#aa0008",  -- NvimLightRed (ErrorMsg, DiffDelete)
	magenta = "#9a0a9a", -- NvimLightMagenta

	-- Dark variants (used as backgrounds on light)
	dark_green = "#005523", -- NvimDarkGreen (DiffAdd bg)
	dark_cyan = "#007373", -- NvimDarkCyan (DiffText bg)
	dark_yellow = "#6b5300", -- NvimDarkYellow (Search bg)
	dark_red = "#590008", -- NvimDarkRed (Error bg)

	-- UI colors
	gray = "#4f5258",    -- NvimDarkGrey4
	gray_light = "#9b9ea4", -- NvimLightGrey4
	gray_dark = "#2c2e33", -- NvimDarkGrey3

	-- Special
	none = "NONE",
}

-- Helper function to set highlights
local function highlight(group, opts)
	local cmd = "highlight " .. group
	if opts.fg then
		cmd = cmd .. " guifg=" .. opts.fg
	end
	if opts.bg then
		cmd = cmd .. " guibg=" .. opts.bg
	end
	if opts.style then
		cmd = cmd .. " gui=" .. opts.style
	end
	if opts.sp then
		cmd = cmd .. " guisp=" .. opts.sp
	end
	if opts.ctermfg then
		cmd = cmd .. " ctermfg=" .. opts.ctermfg
	end
	if opts.ctermbg then
		cmd = cmd .. " ctermbg=" .. opts.ctermbg
	end
	if opts.cterm then
		cmd = cmd .. " cterm=" .. opts.cterm
	end
	if opts.blend then
		cmd = cmd .. " blend=" .. opts.blend
	end
	vim.cmd(cmd)
end

-- Link a highlight group to another
local function link(group, target)
	vim.cmd("highlight default link " .. group .. " " .. target)
end

function M.setup()
	-- Reset highlights
	vim.cmd("highlight clear")
	if vim.fn.exists("syntax_on") then
		vim.cmd("syntax reset")
	end

	vim.o.termguicolors = true
	vim.g.colors_name = "default"

	-- ====================================================================
	-- EDITOR / UI
	-- ====================================================================

	-- Base
	highlight("Normal", { fg = colors.fg, bg = colors.bg })
	highlight("NormalFloat", { bg = colors.bg_float })

	-- Cursor
	highlight("Cursor", { fg = colors.bg, bg = colors.fg })
	highlight("lCursor", { fg = colors.bg, bg = colors.fg })

	-- Current line / column
	highlight("CursorLine", { bg = colors.bg_light })
	highlight("CursorColumn", { bg = colors.bg_light })
	highlight("ColorColumn", { bg = colors.bg_lighter })

	-- Visual selection
	highlight("Visual", { bg = colors.bg_lighter })

	-- Line numbers
	highlight("LineNr", { fg = colors.fg_dark })
	highlight("CursorLineNr", { style = "bold" })
	highlight("SignColumn", { fg = colors.fg_dark })

	-- Search
	highlight("Search", { fg = colors.fg_light, bg = colors.dark_yellow })
	highlight("CurSearch", { fg = colors.bg_alt, bg = colors.yellow })
	highlight("MatchParen", { bg = colors.bg_lighter, style = "bold,underline" })

	-- Status line
	highlight("StatusLine", { fg = colors.fg, bg = colors.bg_statusline })
	highlight("StatusLineNC", { fg = colors.gray_light, bg = colors.bg_light, style = "bold,underline" })
	highlight("WinBar", { fg = colors.fg_alt, bg = colors.bg_alt, style = "bold" })
	highlight("WinBarNC", { fg = colors.fg_alt, bg = colors.bg_alt, style = "bold" })

	-- Tabs
	highlight("TabLineSel", { style = "bold" })

	-- Popup menu
	highlight("Pmenu", { bg = colors.bg_light })
	highlight("PmenuSel", { style = "reverse,underline" })
	highlight("PmenuThumb", { bg = colors.bg_lighter })
	highlight("PmenuMatch", { style = "bold" })
	highlight("PmenuMatchSel", { style = "bold" })

	-- Messages
	highlight("ModeMsg", { fg = colors.green })
	highlight("MoreMsg", { fg = colors.cyan })
	highlight("ErrorMsg", { fg = colors.red })
	highlight("WarningMsg", { fg = colors.yellow })

	-- Float / shadows
	highlight("FloatShadow", { bg = colors.bg_lighter, blend = 80 })
	highlight("FloatShadowThrough", { bg = colors.bg_lighter, blend = 100 })

	-- Folds
	highlight("Folded", { fg = colors.fg_alt, bg = colors.bg_alt })

	-- Diffs
	highlight("DiffAdd", { fg = colors.fg_light, bg = colors.dark_green })
	highlight("DiffChange", { fg = colors.fg_light, bg = colors.bg_lighter })
	highlight("DiffDelete", { fg = colors.red, style = "bold" })
	highlight("DiffText", { fg = colors.fg_light, bg = colors.dark_cyan })

	-- Spelling
	highlight("SpellBad", { sp = colors.red, style = "undercurl" })
	highlight("SpellCap", { sp = colors.yellow, style = "undercurl" })
	highlight("SpellLocal", { sp = colors.green, style = "undercurl" })
	highlight("SpellRare", { sp = colors.cyan, style = "undercurl" })

	-- Misc UI
	highlight("Directory", { fg = colors.cyan })
	highlight("Title", { fg = colors.fg, style = "bold" })
	highlight("Question", { fg = colors.cyan })
	highlight("NonText", { fg = colors.fg_dark })
	highlight("Conceal", { fg = colors.fg_dark })

	-- ====================================================================
	-- SYNTAX
	-- ====================================================================

	-- Base syntax (all mapped to Normal foreground for maximum contrast)
	highlight("Constant", { fg = colors.fg })
	highlight("Operator", { fg = colors.fg })
	highlight("PreProc", { fg = colors.fg })
	highlight("Type", { fg = colors.fg })
	highlight("Delimiter", { fg = colors.fg })

	-- Comment
	highlight("Comment", { fg = colors.fg_alt })

	-- Colored syntax groups
	highlight("String", { fg = colors.green })
	highlight("Identifier", { fg = colors.blue })
	highlight("Function", { fg = colors.cyan })
	highlight("Special", { fg = colors.cyan })
	highlight("Statement", { fg = colors.fg, style = "bold" })

	-- Error / Todo
	highlight("Error", { fg = colors.fg_light, bg = colors.dark_red })
	highlight("Todo", { fg = colors.fg, style = "bold" })

	-- Underlined
	highlight("Underlined", { style = "underline" })

	-- ====================================================================
	-- DIAGNOSTIC
	-- ====================================================================

	highlight("DiagnosticError", { fg = colors.red })
	highlight("DiagnosticWarn", { fg = colors.yellow })
	highlight("DiagnosticInfo", { fg = colors.cyan })
	highlight("DiagnosticHint", { fg = colors.blue })
	highlight("DiagnosticOk", { fg = colors.green })
	highlight("DiagnosticDeprecated", { sp = colors.red, style = "strikethrough" })

	highlight("DiagnosticUnderlineError", { sp = colors.red, style = "underline" })
	highlight("DiagnosticUnderlineWarn", { sp = colors.yellow, style = "underline" })
	highlight("DiagnosticUnderlineInfo", { sp = colors.cyan, style = "underline" })
	highlight("DiagnosticUnderlineHint", { sp = colors.blue, style = "underline" })
	highlight("DiagnosticUnderlineOk", { sp = colors.green, style = "underline" })

	-- ====================================================================
	-- LINKS (default link groups from highlight_init_both[])
	-- ====================================================================

	-- UI links
	link("CursorIM", "Cursor")
	link("EndOfBuffer", "NonText")
	link("FloatBorder", "NormalFloat")
	link("FloatTitle", "Title")
	link("FoldColumn", "SignColumn")
	link("IncSearch", "CurSearch")
	link("LineNrAbove", "LineNr")
	link("LineNrBelow", "LineNr")
	link("MsgSeparator", "StatusLine")
	link("MsgArea", "NONE")
	link("NormalNC", "NONE")
	link("PmenuExtra", "Pmenu")
	link("PmenuExtraSel", "PmenuSel")
	link("PmenuKind", "Pmenu")
	link("PmenuKindSel", "PmenuSel")
	link("PmenuSbar", "Pmenu")
	link("PmenuBorder", "Pmenu")
	link("PmenuShadow", "FloatShadow")
	link("PmenuShadowThrough", "FloatShadowThrough")
	link("PreInsert", "Added")
	link("ComplMatchIns", "NONE")
	link("ComplHint", "NonText")
	link("ComplHintMore", "MoreMsg")
	link("Substitute", "Search")
	link("StatusLineTerm", "StatusLine")
	link("StatusLineTermNC", "StatusLineNC")
	link("StderrMsg", "ErrorMsg")
	link("StdoutMsg", "NONE")
	link("TabLine", "StatusLineNC")
	link("TabLineFill", "TabLine")
	link("VertSplit", "WinSeparator")
	link("VisualNOS", "Visual")
	link("Whitespace", "NonText")
	link("WildMenu", "PmenuSel")
	link("WinSeparator", "Normal")

	-- Diff
	link("DiffTextAdd", "DiffText")
	link("CursorLineFold", "FoldColumn")
	link("CursorLineSign", "SignColumn")

	-- Syntax links
	link("Character", "Constant")
	link("Number", "Constant")
	link("Boolean", "Constant")
	link("Float", "Number")
	link("Conditional", "Statement")
	link("Repeat", "Statement")
	link("Label", "Statement")
	link("Keyword", "Statement")
	link("Exception", "Statement")
	link("Include", "PreProc")
	link("Define", "PreProc")
	link("Macro", "PreProc")
	link("PreCondit", "PreProc")
	link("StorageClass", "Type")
	link("Structure", "Type")
	link("Typedef", "Type")
	link("Tag", "Special")
	link("SpecialChar", "Special")
	link("SpecialComment", "Special")
	link("Debug", "Special")
	link("SpecialKey", "Special")
	link("Dimmed", "Comment")
	link("Ignore", "Normal")

	-- ====================================================================
	-- TREESITTER STANDARD GROUPS
	-- ====================================================================

	-- Variables
	highlight("@variable", { fg = colors.fg })
	link("@variable.builtin", "Special")
	link("@variable.parameter.builtin", "Special")

	-- Constants
	link("@constant", "Constant")
	link("@constant.builtin", "Special")

	-- Modules
	link("@module", "Structure")
	link("@module.builtin", "Special")
	link("@label", "Label")

	-- Strings
	link("@string", "String")
	link("@string.special", "SpecialChar")
	link("@string.special.url", "Underlined")

	-- Characters
	link("@character", "Character")
	link("@character.special", "SpecialChar")

	-- Booleans / Numbers
	link("@boolean", "Boolean")
	link("@number", "Number")
	link("@number.float", "Float")

	-- Types
	link("@type", "Type")
	link("@type.builtin", "Special")

	-- Attributes / Properties
	link("@attribute", "Macro")
	link("@attribute.builtin", "Special")
	link("@property", "Identifier")

	-- Functions
	link("@function", "Function")
	link("@function.builtin", "Special")

	-- Constructors / Operators
	link("@constructor", "Special")
	link("@operator", "Operator")

	-- Keywords
	link("@keyword", "Keyword")

	-- Punctuation
	link("@punctuation", "Delimiter")
	link("@punctuation.special", "Special")

	-- Comments
	link("@comment", "Comment")
	link("@comment.error", "DiagnosticError")
	link("@comment.warning", "DiagnosticWarn")
	link("@comment.note", "DiagnosticInfo")
	link("@comment.todo", "Todo")

	-- Markup
	highlight("@markup.strong", { style = "bold" })
	highlight("@markup.italic", { style = "italic" })
	highlight("@markup.strikethrough", { style = "strikethrough" })
	highlight("@markup.underline", { style = "underline" })

	link("@markup", "Special")
	link("@markup.heading", "Title")
	link("@markup.link", "Underlined")

	-- Diff
	link("@diff.plus", "Added")
	link("@diff.minus", "Removed")
	link("@diff.delta", "Changed")

	-- Tags
	link("@tag", "Tag")
	link("@tag.builtin", "Special")

	-- Vimdoc heading delimiters
	highlight("@markup.heading.1.delimiter.vimdoc",
		{ fg = colors.bg, bg = colors.bg, sp = colors.fg, style = "underdouble,nocombine" })
	highlight("@markup.heading.2.delimiter.vimdoc",
		{ fg = colors.bg, bg = colors.bg, sp = colors.fg, style = "underline,nocombine" })

	-- ====================================================================
	-- LSP SEMANTIC TOKENS
	-- ====================================================================

	link("@lsp.type.class", "@type")
	link("@lsp.type.comment", "@comment")
	link("@lsp.type.decorator", "@attribute")
	link("@lsp.type.enum", "@type")
	link("@lsp.type.enumMember", "@constant")
	link("@lsp.type.event", "@type")
	link("@lsp.type.function", "@function")
	link("@lsp.type.interface", "@type")
	link("@lsp.type.keyword", "@keyword")
	link("@lsp.type.macro", "@constant.macro")
	link("@lsp.type.method", "@function.method")
	link("@lsp.type.modifier", "@type.qualifier")
	link("@lsp.type.namespace", "@module")
	link("@lsp.type.number", "@number")
	link("@lsp.type.operator", "@operator")
	link("@lsp.type.parameter", "@variable.parameter")
	link("@lsp.type.property", "@property")
	link("@lsp.type.regexp", "@string.regexp")
	link("@lsp.type.string", "@string")
	link("@lsp.type.struct", "@type")
	link("@lsp.type.type", "@type")
	link("@lsp.type.typeParameter", "@type.definition")
	link("@lsp.type.variable", "@variable")

	link("@lsp.mod.deprecated", "DiagnosticDeprecated")

	-- LSP UI
	link("LspCodeLens", "NonText")
	link("LspCodeLensSeparator", "LspCodeLens")
	link("LspInlayHint", "NonText")
	link("LspReferenceText", "Visual")
	link("LspReferenceRead", "LspReferenceText")
	link("LspReferenceWrite", "LspReferenceText")
	link("LspReferenceTarget", "LspReferenceText")
	link("LspSignatureActiveParameter", "Visual")
	link("SnippetTabstop", "Visual")
	link("SnippetTabstopActive", "SnippetTabstop")

	-- ====================================================================
	-- PLUGIN: Telescope
	-- ====================================================================

	highlight("TelescopeNormal", { fg = colors.fg, bg = colors.bg_float })
	highlight("TelescopeBorder", { fg = colors.cyan, bg = colors.bg_float })
	highlight("TelescopePromptBorder", { fg = colors.green, bg = colors.bg_float })
	highlight("TelescopeResultsBorder", { fg = colors.blue, bg = colors.bg_float })
	highlight("TelescopePreviewBorder", { fg = colors.cyan, bg = colors.bg_float })
	highlight("TelescopeSelection", { fg = colors.fg_light, bg = colors.bg_light })
	highlight("TelescopeSelectionCaret", { fg = colors.yellow, bg = colors.bg_light })
	highlight("TelescopeMultiSelection", { fg = colors.blue, bg = colors.bg_light })
	highlight("TelescopeMatching", { fg = colors.yellow, style = "bold" })
	highlight("TelescopePromptPrefix", { fg = colors.cyan })

	-- ====================================================================
	-- PLUGIN: NvimTree
	-- ====================================================================

	highlight("NvimTreeNormal", { fg = colors.fg, bg = colors.bg })
	highlight("NvimTreeWinSeparator", { fg = colors.fg_dark, bg = colors.bg })
	highlight("NvimTreeRootFolder", { fg = colors.cyan, style = "bold" })
	highlight("NvimTreeFolderName", { fg = colors.blue })
	highlight("NvimTreeFolderIcon", { fg = colors.blue })
	highlight("NvimTreeOpenedFolderName", { fg = colors.cyan })
	highlight("NvimTreeIndentMarker", { fg = colors.fg_dark })
	highlight("NvimTreeGitDirty", { fg = colors.yellow })
	highlight("NvimTreeGitNew", { fg = colors.green })
	highlight("NvimTreeGitDeleted", { fg = colors.red })
	highlight("NvimTreeSpecialFile", { fg = colors.cyan })
	highlight("NvimTreeImageFile", { fg = colors.magenta })
	highlight("NvimTreeExecFile", { fg = colors.green })

	-- ====================================================================
	-- PLUGIN: IndentBlankline
	-- ====================================================================

	highlight("IndentBlanklineChar", { fg = colors.gray_dark })
	highlight("IndentBlanklineContextChar", { fg = colors.blue })
	highlight("IndentBlanklineContextStart", { sp = colors.blue, style = "underline" })

	-- ====================================================================
	-- PLUGIN: Which-key
	-- ====================================================================

	highlight("WhichKey", { fg = colors.cyan })
	highlight("WhichKeyGroup", { fg = colors.blue })
	highlight("WhichKeyDesc", { fg = colors.fg })
	highlight("WhichKeySeperator", { fg = colors.fg_dark })
	highlight("WhichKeyFloat", { bg = colors.bg_float })
	highlight("WhichKeyBorder", { fg = colors.blue })

	-- ====================================================================
	-- PLUGIN: BufferLine
	-- ====================================================================

	highlight("BufferLineIndicatorSelected", { fg = colors.cyan })
	highlight("BufferLineFill", { bg = colors.bg_alt })

	-- ====================================================================
	-- PLUGIN: Notify
	-- ====================================================================

	highlight("NotifyBackground", { bg = colors.bg_float })
	highlight("NotifyERRORBorder", { fg = colors.red })
	highlight("NotifyWARNBorder", { fg = colors.yellow })
	highlight("NotifyINFOBorder", { fg = colors.cyan })
	highlight("NotifyDEBUGBorder", { fg = colors.fg_dark })
	highlight("NotifyTRACEBorder", { fg = colors.blue })

	-- ====================================================================
	-- PLUGIN: nvim-cmp
	-- ====================================================================

	highlight("CmpItemAbbrDeprecated", { fg = colors.fg_dark, style = "strikethrough" })
	highlight("CmpItemAbbrMatch", { fg = colors.yellow, style = "bold" })
	highlight("CmpItemAbbrMatchFuzzy", { fg = colors.yellow, style = "bold" })
	highlight("CmpItemKindVariable", { fg = colors.cyan })
	highlight("CmpItemKindInterface", { fg = colors.cyan })
	highlight("CmpItemKindText", { fg = colors.cyan })
	highlight("CmpItemKindFunction", { fg = colors.blue })
	highlight("CmpItemKindMethod", { fg = colors.blue })
	highlight("CmpItemKindKeyword", { fg = colors.fg })
	highlight("CmpItemKindProperty", { fg = colors.fg })
	highlight("CmpItemKindUnit", { fg = colors.fg })

	-- ====================================================================
	-- PLUGIN: Git signs / gitsigns
	-- ====================================================================

	highlight("GitSignsAdd", { fg = colors.green })
	highlight("GitSignsChange", { fg = colors.yellow })
	highlight("GitSignsDelete", { fg = colors.red })

	-- ====================================================================
	-- MARKDOWN / HTML (plugin-based)
	-- ====================================================================

	highlight("markdownCode", { fg = colors.green, bg = colors.bg_light })
	highlight("markdownCodeBlock", { fg = colors.fg_alt, bg = colors.bg_light })
	highlight("markdownCodeDelimiter", { fg = colors.fg_dark, bg = colors.bg_light })
	highlight("markdownH1", { fg = colors.fg, style = "bold" })
	highlight("markdownH2", { fg = colors.fg, style = "bold" })
	highlight("markdownH3", { fg = colors.cyan, style = "bold" })
	highlight("markdownH4", { fg = colors.cyan })
	highlight("markdownH5", { fg = colors.blue })
	highlight("markdownH6", { fg = colors.blue })
	highlight("markdownHeadingDelimiter", { fg = colors.fg, style = "bold" })
	highlight("markdownHeadingRule", { fg = colors.fg, style = "bold" })
	highlight("markdownBold", { fg = colors.fg, style = "bold" })
	highlight("markdownItalic", { fg = colors.fg, style = "italic" })
	highlight("markdownBoldItalic", { fg = colors.fg, style = "bold,italic" })
	highlight("markdownUrl", { fg = colors.cyan, style = "underline" })
	highlight("markdownLink", { fg = colors.blue })
	highlight("markdownLinkText", { fg = colors.blue })
	highlight("markdownLinkDelimiter", { fg = colors.fg_dark })
	highlight("markdownLinkTextDelimiter", { fg = colors.fg_dark })
	highlight("markdownListMarker", { fg = colors.cyan })
	highlight("markdownOrderedListMarker", { fg = colors.cyan })
	highlight("markdownRule", { fg = colors.fg_dark })
	highlight("markdownBlockquote", { fg = colors.fg_alt, style = "italic" })

	-- Treesitter markdown
	highlight("@markup.heading.1.markdown", { fg = colors.fg, style = "bold" })
	highlight("@markup.heading.2.markdown", { fg = colors.fg, style = "bold" })
	highlight("@markup.heading.3.markdown", { fg = colors.cyan, style = "bold" })
	highlight("@markup.heading.4.markdown", { fg = colors.cyan })
	highlight("@markup.heading.5.markdown", { fg = colors.blue })
	highlight("@markup.heading.6.markdown", { fg = colors.blue })
	highlight("@markup.strong.markdown_inline", { fg = colors.fg, style = "bold" })
	highlight("@markup.italic.markdown_inline", { fg = colors.fg, style = "italic" })
	highlight("@markup.raw.markdown_inline", { fg = colors.green, bg = colors.bg_light })
	highlight("@markup.raw.block.markdown", { fg = colors.fg_alt, bg = colors.bg_light })
	highlight("@markup.link.label.markdown_inline", { fg = colors.blue })
	highlight("@markup.link.url.markdown_inline", { fg = colors.cyan, style = "underline" })
	highlight("@markup.list.markdown", { fg = colors.cyan })
	highlight("@markup.quote.markdown", { fg = colors.fg_alt, style = "italic" })

	-- HTML headings
	highlight("htmlH1", { fg = colors.fg, style = "bold" })
	highlight("htmlH2", { fg = colors.fg, style = "bold" })
	highlight("htmlH3", { fg = colors.cyan, style = "bold" })
	highlight("htmlH4", { fg = colors.cyan })
	highlight("htmlH5", { fg = colors.blue })
	highlight("htmlH6", { fg = colors.blue })

	-- Fenced code blocks
	highlight("@markup.raw.delimiter.markdown", { fg = colors.fg_dark, bg = colors.bg_light })
	highlight("@markup.raw.language.markdown", { fg = colors.cyan, bg = colors.bg_light })

	-- vim-markdown plugin
	highlight("mkdCodeDelimiter", { fg = colors.fg_dark, bg = colors.bg_light })
	highlight("mkdCodeStart", { fg = colors.fg_dark, bg = colors.bg_light })
	highlight("mkdCodeEnd", { fg = colors.fg_dark, bg = colors.bg_light })
	highlight("mkdCode", { fg = colors.green, bg = colors.bg_light })
end

return M
