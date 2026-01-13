-- Nord colorscheme for Neovim
-- Based on Nord color palette

local M = {}

-- Nord color palette
local colors = {
	-- Core backgrounds
	bg = "#2E3440",         -- Nord0 - Polar Night
	bg_alt = "#3B4252",     -- Nord1 - Slightly lighter
	bg_light = "#434C5E",   -- Nord2 - Current line, selections
	bg_lighter = "#4C566A", -- Nord3 - Visual mode, folds

	-- Special backgrounds
	bg_statusline = "#2E3440", -- Status line background
	bg_float = "#3B4252",      -- Floating window background

	-- Foreground colors
	fg = "#D8DEE9",       -- Nord4 - Main text
	fg_alt = "#E5E9F0",   -- Nord5 - Secondary text
	fg_dark = "#4C566A",  -- Nord3 - Comments, line numbers
	fg_light = "#ECEFF4", -- Nord6 - Light text

	-- Primary syntax colors - Nord Frost
	blue = "#81A1C1",       -- Nord9 - Keywords, types
	light_blue = "#88C0D0", -- Nord8 - Functions, identifiers
	dark_blue = "#5E81AC",  -- Nord10 - Special elements
	cyan = "#8FBCBB",       -- Nord7 - Constants, built-ins

	-- Nord Aurora accent colors
	pink = "#B48EAD",    -- Nord15 - Errors, important highlights
	purple = "#B48EAD",  -- Nord15 - Statements, control flow
	magenta = "#B48EAD", -- Nord15 - Special elements
	orange = "#D08770",  -- Nord12 - Characters, special chars

	-- Complementary colors
	green = "#A3BE8C",  -- Nord14 - Strings, success states
	yellow = "#EBCB8B", -- Nord13 - Numbers, warnings
	red = "#BF616A",    -- Nord11 - Errors, deletions

	-- UI element colors
	gray = "#4C566A",       -- Nord3 - Borders, separators
	gray_light = "#616E88", -- Lighter borders
	gray_dark = "#3B4252",  -- Nord1 - Dark borders

	-- Accent highlights
	glow_pink = "#B48EAD",  -- Nord15 for emphasis
	glow_blue = "#88C0D0",  -- Nord8 for emphasis
	glow_purple = "#B48EAD", -- Nord15 for emphasis

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
	vim.cmd(cmd)
end

function M.setup()
	-- Reset highlights
	vim.cmd("highlight clear")
	if vim.fn.exists("syntax_on") then
		vim.cmd("syntax reset")
	end

	vim.o.termguicolors = true
	vim.g.colors_name = "nord"

	-- Editor highlights
	highlight("Normal", { fg = colors.fg, bg = colors.bg })
	highlight("NormalFloat", { fg = colors.fg, bg = colors.bg_float })
	highlight("NormalNC", { fg = colors.fg_alt, bg = colors.bg })

	-- Cursor and selection
	highlight("Cursor", { fg = colors.bg, bg = colors.fg })
	highlight("CursorLine", { bg = colors.bg_light })
	highlight("CursorColumn", { bg = colors.bg_lighter })
	highlight("ColorColumn", { bg = colors.bg_lighter })
	highlight("Visual", { bg = colors.bg_lighter })
	highlight("VisualNOS", { bg = colors.bg_lighter })

	-- Line numbers
	highlight("LineNr", { fg = colors.gray })
	highlight("CursorLineNr", { fg = colors.fg_light, style = "bold" })
	highlight("SignColumn", { fg = colors.gray, bg = colors.bg })

	-- Search and matching
	highlight("Search", { fg = colors.bg, bg = colors.yellow })
	highlight("IncSearch", { fg = colors.bg, bg = colors.cyan })
	highlight("MatchParen", { fg = colors.cyan, style = "bold" })

	-- Splits and windows
	highlight("VertSplit", { fg = colors.gray, bg = colors.bg })
	highlight("WinSeparator", { fg = colors.gray, bg = colors.bg })
	highlight("StatusLine", { fg = colors.fg, bg = colors.bg_light })
	highlight("StatusLineNC", { fg = colors.fg_dark, bg = colors.bg_statusline })

	-- Tabs
	highlight("TabLine", { fg = colors.fg_dark, bg = colors.bg_light })
	highlight("TabLineSel", { fg = colors.cyan, bg = colors.bg_lighter })
	highlight("TabLineFill", { bg = colors.bg_light })

	-- Popup menu
	highlight("Pmenu", { fg = colors.fg, bg = colors.bg_alt })
	highlight("PmenuSel", { fg = colors.cyan, bg = colors.bg_lighter })
	highlight("PmenuSbar", { bg = colors.gray_dark })
	highlight("PmenuThumb", { bg = colors.gray })

	-- Messages and command line
	highlight("ModeMsg", { fg = colors.cyan, style = "bold" })
	highlight("MoreMsg", { fg = colors.green, style = "bold" })
	highlight("ErrorMsg", { fg = colors.red, style = "bold" })
	highlight("WarningMsg", { fg = colors.orange, style = "bold" })

	-- Folds
	highlight("Folded", { fg = colors.fg_dark, bg = colors.bg_light })
	highlight("FoldColumn", { fg = colors.gray, bg = colors.bg })

	-- Diffs
	highlight("DiffAdd", { fg = colors.green, bg = colors.bg })
	highlight("DiffChange", { fg = colors.yellow, bg = colors.bg })
	highlight("DiffDelete", { fg = colors.red, bg = colors.bg })
	highlight("DiffText", { fg = colors.yellow, bg = colors.gray_dark })

	-- Spelling
	highlight("SpellBad", { sp = colors.red, style = "undercurl" })
	highlight("SpellCap", { sp = colors.blue, style = "undercurl" })
	highlight("SpellLocal", { sp = colors.cyan, style = "undercurl" })
	highlight("SpellRare", { sp = colors.purple, style = "undercurl" })

	-- Miscellaneous
	highlight("Directory", { fg = colors.light_blue })
	highlight("Title", { fg = colors.cyan, style = "bold" })
	highlight("Question", { fg = colors.green })
	highlight("NonText", { fg = colors.gray })
	highlight("SpecialKey", { fg = colors.gray })
	highlight("Whitespace", { fg = colors.gray_dark })

	-- Syntax highlighting
	highlight("Comment", { fg = colors.gray_light, style = "italic" })
	highlight("Constant", { fg = colors.cyan })
	highlight("String", { fg = colors.green })
	highlight("Character", { fg = colors.orange })
	highlight("Number", { fg = colors.purple })
	highlight("Boolean", { fg = colors.blue })
	highlight("Float", { fg = colors.purple })

	highlight("Identifier", { fg = colors.fg })
	highlight("Function", { fg = colors.light_blue })

	highlight("Statement", { fg = colors.blue, style = "bold" })
	highlight("Conditional", { fg = colors.blue })
	highlight("Repeat", { fg = colors.blue })
	highlight("Label", { fg = colors.blue })
	highlight("Operator", { fg = colors.cyan })
	highlight("Keyword", { fg = colors.blue })
	highlight("Exception", { fg = colors.blue })

	highlight("PreProc", { fg = colors.blue })
	highlight("Include", { fg = colors.blue })
	highlight("Define", { fg = colors.blue })
	highlight("Macro", { fg = colors.purple })
	highlight("PreCondit", { fg = colors.blue })

	highlight("Type", { fg = colors.light_blue })
	highlight("StorageClass", { fg = colors.blue })
	highlight("Structure", { fg = colors.blue })
	highlight("Typedef", { fg = colors.blue })

	highlight("Special", { fg = colors.orange })
	highlight("SpecialChar", { fg = colors.orange })
	highlight("Tag", { fg = colors.blue })
	highlight("Delimiter", { fg = colors.fg_alt })
	highlight("SpecialComment", { fg = colors.gray_light })
	highlight("Debug", { fg = colors.red })

	highlight("Underlined", { style = "underline" })
	highlight("Ignore", { fg = colors.gray })
	highlight("Error", { fg = colors.red, style = "bold" })
	highlight("Todo", { fg = colors.yellow, bg = colors.bg, style = "bold" })

	-- Treesitter highlights
	highlight("@comment", { fg = colors.gray_light, style = "italic" })
	highlight("@comment.documentation", { fg = colors.gray_light, style = "italic" })

	highlight("@keyword", { fg = colors.blue })
	highlight("@keyword.function", { fg = colors.blue })
	highlight("@keyword.operator", { fg = colors.blue })
	highlight("@keyword.return", { fg = colors.blue })
	highlight("@keyword.conditional", { fg = colors.blue })
	highlight("@keyword.repeat", { fg = colors.blue })
	highlight("@keyword.import", { fg = colors.blue })

	highlight("@function", { fg = colors.light_blue })
	highlight("@function.builtin", { fg = colors.cyan })
	highlight("@function.call", { fg = colors.light_blue })
	highlight("@function.macro", { fg = colors.blue })
	highlight("@method", { fg = colors.light_blue })
	highlight("@method.call", { fg = colors.light_blue })

	highlight("@variable", { fg = colors.fg })
	highlight("@variable.builtin", { fg = colors.cyan })
	highlight("@variable.parameter", { fg = colors.fg })
	highlight("@variable.member", { fg = colors.fg })

	highlight("@string", { fg = colors.green })
	highlight("@string.documentation", { fg = colors.green })
	highlight("@string.regex", { fg = colors.orange })
	highlight("@string.escape", { fg = colors.orange })

	highlight("@character", { fg = colors.orange })
	highlight("@character.special", { fg = colors.orange })

	highlight("@number", { fg = colors.purple })
	highlight("@number.float", { fg = colors.purple })
	highlight("@boolean", { fg = colors.blue })

	highlight("@type", { fg = colors.light_blue })
	highlight("@type.builtin", { fg = colors.blue })
	highlight("@type.definition", { fg = colors.light_blue })

	highlight("@constant", { fg = colors.cyan })
	highlight("@constant.builtin", { fg = colors.cyan })
	highlight("@constant.macro", { fg = colors.cyan })

	highlight("@constructor", { fg = colors.light_blue })
	highlight("@namespace", { fg = colors.fg })
	highlight("@module", { fg = colors.fg })

	highlight("@operator", { fg = colors.cyan })
	highlight("@punctuation.delimiter", { fg = colors.fg_alt })
	highlight("@punctuation.bracket", { fg = colors.fg_alt })
	highlight("@punctuation.special", { fg = colors.orange })

	highlight("@tag", { fg = colors.blue })
	highlight("@tag.attribute", { fg = colors.light_blue })
	highlight("@tag.delimiter", { fg = colors.fg_alt })

	highlight("@property", { fg = colors.fg })
	highlight("@field", { fg = colors.fg })

	highlight("@label", { fg = colors.blue })

	-- LSP highlights
	highlight("DiagnosticError", { fg = colors.red })
	highlight("DiagnosticWarn", { fg = colors.orange })
	highlight("DiagnosticInfo", { fg = colors.cyan })
	highlight("DiagnosticHint", { fg = colors.green })

	highlight("DiagnosticUnderlineError", { sp = colors.red, style = "undercurl" })
	highlight("DiagnosticUnderlineWarn", { sp = colors.orange, style = "undercurl" })
	highlight("DiagnosticUnderlineInfo", { sp = colors.cyan, style = "undercurl" })
	highlight("DiagnosticUnderlineHint", { sp = colors.green, style = "undercurl" })

	highlight("LspReferenceText", { bg = colors.bg_light })
	highlight("LspReferenceRead", { bg = colors.bg_light })
	highlight("LspReferenceWrite", { bg = colors.bg_light })

	highlight("LspSignatureActiveParameter", { fg = colors.cyan, style = "bold" })

	-- Git signs
	highlight("GitSignsAdd", { fg = colors.green })
	highlight("GitSignsChange", { fg = colors.orange })
	highlight("GitSignsDelete", { fg = colors.red })

	-- Telescope
	highlight("TelescopeNormal", { fg = colors.fg, bg = colors.bg_float })
	highlight("TelescopeBorder", { fg = colors.blue, bg = colors.bg_float })
	highlight("TelescopePromptBorder", { fg = colors.cyan, bg = colors.bg_float })
	highlight("TelescopeResultsBorder", { fg = colors.blue, bg = colors.bg_float })
	highlight("TelescopePreviewBorder", { fg = colors.blue, bg = colors.bg_float })

	highlight("TelescopeSelection", { fg = colors.fg_light, bg = colors.bg_light })
	highlight("TelescopeSelectionCaret", { fg = colors.cyan, bg = colors.bg_light })
	highlight("TelescopeMultiSelection", { fg = colors.purple, bg = colors.bg_light })

	highlight("TelescopeMatching", { fg = colors.cyan, style = "bold" })
	highlight("TelescopePromptPrefix", { fg = colors.cyan })

	-- NvimTree
	highlight("NvimTreeNormal", { fg = colors.fg, bg = colors.bg_alt })
	highlight("NvimTreeWinSeparator", { fg = colors.gray, bg = colors.bg_alt })
	highlight("NvimTreeRootFolder", { fg = colors.cyan, style = "bold" })
	highlight("NvimTreeFolderName", { fg = colors.light_blue })
	highlight("NvimTreeFolderIcon", { fg = colors.light_blue })
	highlight("NvimTreeOpenedFolderName", { fg = colors.cyan })
	highlight("NvimTreeIndentMarker", { fg = colors.gray })
	highlight("NvimTreeGitDirty", { fg = colors.orange })
	highlight("NvimTreeGitNew", { fg = colors.green })
	highlight("NvimTreeGitDeleted", { fg = colors.red })
	highlight("NvimTreeSpecialFile", { fg = colors.purple })
	highlight("NvimTreeImageFile", { fg = colors.purple })
	highlight("NvimTreeExecFile", { fg = colors.green })

	-- IndentBlankline
	highlight("IndentBlanklineChar", { fg = colors.gray_dark })
	highlight("IndentBlanklineContextChar", { fg = colors.cyan })
	highlight("IndentBlanklineContextStart", { sp = colors.cyan, style = "underline" })

	-- Which-key
	highlight("WhichKey", { fg = colors.cyan })
	highlight("WhichKeyGroup", { fg = colors.blue })
	highlight("WhichKeyDesc", { fg = colors.fg })
	highlight("WhichKeySeperator", { fg = colors.gray })
	highlight("WhichKeyFloat", { bg = colors.bg_float })
	highlight("WhichKeyBorder", { fg = colors.blue })

	-- BufferLine
	highlight("BufferLineIndicatorSelected", { fg = colors.cyan })
	highlight("BufferLineFill", { bg = colors.bg_statusline })

	-- Notify
	highlight("NotifyBackground", { bg = colors.bg_float })
	highlight("NotifyERRORBorder", { fg = colors.red })
	highlight("NotifyWARNBorder", { fg = colors.orange })
	highlight("NotifyINFOBorder", { fg = colors.cyan })
	highlight("NotifyDEBUGBorder", { fg = colors.gray })
	highlight("NotifyTRACEBorder", { fg = colors.purple })

	-- CMP (completion)
	highlight("CmpItemAbbrDeprecated", { fg = colors.gray, style = "strikethrough" })
	highlight("CmpItemAbbrMatch", { fg = colors.cyan, style = "bold" })
	highlight("CmpItemAbbrMatchFuzzy", { fg = colors.cyan, style = "bold" })
	highlight("CmpItemKindVariable", { fg = colors.fg })
	highlight("CmpItemKindInterface", { fg = colors.light_blue })
	highlight("CmpItemKindText", { fg = colors.fg })
	highlight("CmpItemKindFunction", { fg = colors.light_blue })
	highlight("CmpItemKindMethod", { fg = colors.light_blue })
	highlight("CmpItemKindKeyword", { fg = colors.blue })
	highlight("CmpItemKindProperty", { fg = colors.fg })
	highlight("CmpItemKindUnit", { fg = colors.fg })

	-- Markdown highlights
	highlight("markdownCode", { fg = colors.green, bg = colors.bg_lighter })
	highlight("markdownCodeBlock", { fg = colors.fg, bg = colors.bg_lighter })
	highlight("markdownCodeDelimiter", { fg = colors.gray, bg = colors.bg_lighter })
	highlight("markdownH1", { fg = colors.cyan, style = "bold" })
	highlight("markdownH2", { fg = colors.cyan, style = "bold" })
	highlight("markdownH3", { fg = colors.light_blue, style = "bold" })
	highlight("markdownH4", { fg = colors.light_blue })
	highlight("markdownH5", { fg = colors.blue })
	highlight("markdownH6", { fg = colors.blue })
	highlight("markdownHeadingDelimiter", { fg = colors.cyan, style = "bold" })
	highlight("markdownHeadingRule", { fg = colors.cyan, style = "bold" })
	highlight("markdownBold", { fg = colors.fg_light, style = "bold" })
	highlight("markdownItalic", { fg = colors.fg_light, style = "italic" })
	highlight("markdownBoldItalic", { fg = colors.fg_light, style = "bold,italic" })
	highlight("markdownUrl", { fg = colors.cyan, style = "underline" })
	highlight("markdownLink", { fg = colors.light_blue })
	highlight("markdownLinkText", { fg = colors.light_blue })
	highlight("markdownLinkDelimiter", { fg = colors.gray })
	highlight("markdownLinkTextDelimiter", { fg = colors.gray })
	highlight("markdownListMarker", { fg = colors.blue })
	highlight("markdownOrderedListMarker", { fg = colors.blue })
	highlight("markdownRule", { fg = colors.gray })
	highlight("markdownBlockquote", { fg = colors.gray_light, style = "italic" })

	-- Treesitter markdown highlights
	highlight("@markup.heading.1.markdown", { fg = colors.cyan, style = "bold" })
	highlight("@markup.heading.2.markdown", { fg = colors.cyan, style = "bold" })
	highlight("@markup.heading.3.markdown", { fg = colors.light_blue, style = "bold" })
	highlight("@markup.heading.4.markdown", { fg = colors.light_blue })
	highlight("@markup.heading.5.markdown", { fg = colors.blue })
	highlight("@markup.heading.6.markdown", { fg = colors.blue })
	highlight("@markup.strong.markdown_inline", { fg = colors.fg_light, style = "bold" })
	highlight("@markup.italic.markdown_inline", { fg = colors.fg_light, style = "italic" })
	highlight("@markup.raw.markdown_inline", { fg = colors.green, bg = colors.bg_lighter })
	highlight("@markup.raw.block.markdown", { fg = colors.fg, bg = colors.bg_lighter })
	highlight("@markup.link.label.markdown_inline", { fg = colors.light_blue })
	highlight("@markup.link.url.markdown_inline", { fg = colors.cyan, style = "underline" })
	highlight("@markup.list.markdown", { fg = colors.blue })
	highlight("@markup.quote.markdown", { fg = colors.gray_light, style = "italic" })

	-- Additional HTML markdown highlights
	highlight("htmlH1", { fg = colors.cyan, style = "bold" })
	highlight("htmlH2", { fg = colors.cyan, style = "bold" })
	highlight("htmlH3", { fg = colors.light_blue, style = "bold" })
	highlight("htmlH4", { fg = colors.light_blue })
	highlight("htmlH5", { fg = colors.blue })
	highlight("htmlH6", { fg = colors.blue })

	-- Fenced code blocks
	highlight("@markup.raw.delimiter.markdown", { fg = colors.gray, bg = colors.bg_lighter })
	highlight("@markup.raw.language.markdown", { fg = colors.blue, bg = colors.bg_lighter })

	-- vim-markdown plugin
	highlight("mkdCodeDelimiter", { fg = colors.gray, bg = colors.bg_lighter })
	highlight("mkdCodeStart", { fg = colors.gray, bg = colors.bg_lighter })
	highlight("mkdCodeEnd", { fg = colors.gray, bg = colors.bg_lighter })
	highlight("mkdCode", { fg = colors.green, bg = colors.bg_lighter })
end

return M
