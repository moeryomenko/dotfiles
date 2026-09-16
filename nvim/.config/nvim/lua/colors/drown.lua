-- Drown colorscheme for Neovim
-- Inspired by cyberpunk/synthwave aesthetic with neon pinks and cyans

local M = {}

-- Color palette from the cyberpunk image
local colors = {
	-- Core backgrounds
	bg = "#1a0a1f",      -- Deep purple-black shadows
	bg_alt = "#250f2e",  -- Slightly lighter purple
	bg_light = "#2f1438", -- Lighter background (current line, selections)
	bg_lighter = "#3a1a45", -- Lightest background (visual mode, folds)

	-- Special backgrounds
	bg_statusline = "#150a1a", -- Status line background
	bg_float = "#1f0e28",   -- Floating window background

	-- Foreground colors
	fg = "#e8d4f2",    -- Main text (soft white with pink tint)
	fg_alt = "#b8a0c8", -- Secondary text (muted purple-gray)
	fg_dark = "#6d5a7a", -- Darker text (comments, line numbers)
	fg_light = "#f5e5ff", -- Light text (keywords, important elements)

	-- Primary syntax colors
	pink = "#ff0080",     -- Hot pink (primary accent)
	pink_bright = "#ff2d9f", -- Bright pink for highlights
	pink_soft = "#d946a6", -- Softer pink for UI elements
	magenta = "#c026d3",  -- Magenta for statements

	cyan = "#00d9ff",     -- Neon cyan (secondary accent)
	cyan_bright = "#4dffff", -- Bright cyan for special elements
	cyan_soft = "#06b6d4", -- Softer cyan for constants

	-- Complementary syntax colors
	purple = "#a855f7",   -- Purple for keywords and control flow
	purple_deep = "#7c3aed", -- Deeper purple for types
	blue = "#3b82f6",     -- Blue for functions

	green = "#10b981",    -- Green for strings and success
	yellow = "#fbbf24",   -- Yellow for warnings and numbers
	orange = "#f97316",   -- Orange for special chars
	red = "#ef4444",      -- Red for errors

	-- UI element colors
	gray = "#4a3d5c",    -- Borders, separators
	gray_light = "#5c4d73", -- Light borders, inactive elements
	gray_dark = "#2d2438", -- Dark borders, disabled elements

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
	vim.g.colors_name = "drown"

	-- Editor highlights
	highlight("Normal", { fg = colors.fg, bg = colors.bg })
	highlight("NormalFloat", { fg = colors.fg, bg = colors.bg_float })
	highlight("NormalNC", { fg = colors.fg_alt, bg = colors.bg })

	-- Cursor and selection
	highlight("Cursor", { fg = colors.bg, bg = colors.cyan_bright })
	highlight("CursorLine", { bg = colors.bg_light })
	highlight("CursorColumn", { bg = colors.bg_lighter })
	highlight("ColorColumn", { bg = colors.bg_lighter })
	highlight("Visual", { bg = colors.purple_deep, fg = colors.fg_light })
	highlight("VisualNOS", { bg = colors.purple_deep })

	-- Line numbers
	highlight("LineNr", { fg = colors.gray })
	highlight("CursorLineNr", { fg = colors.pink_bright, style = "bold" })
	highlight("SignColumn", { fg = colors.gray, bg = colors.bg })

	-- Search and matching
	highlight("Search", { fg = colors.bg, bg = colors.pink_bright })
	highlight("IncSearch", { fg = colors.bg, bg = colors.cyan_bright })
	highlight("MatchParen", { fg = colors.cyan_bright, style = "bold" })

	-- Splits and windows
	highlight("VertSplit", { fg = colors.pink_soft, bg = colors.bg })
	highlight("WinSeparator", { fg = colors.pink_soft, bg = colors.bg })
	highlight("StatusLine", { fg = colors.pink_bright, bg = colors.bg_light })
	highlight("StatusLineNC", { fg = colors.fg_dark, bg = colors.bg_statusline })

	-- Tabs
	highlight("TabLine", { fg = colors.fg_dark, bg = colors.bg_light })
	highlight("TabLineSel", { fg = colors.cyan_bright, bg = colors.purple_deep })
	highlight("TabLineFill", { bg = colors.bg_light })

	-- Popup menu
	highlight("Pmenu", { fg = colors.fg, bg = colors.bg_alt })
	highlight("PmenuSel", { fg = colors.fg_light, bg = colors.purple_deep })
	highlight("PmenuSbar", { bg = colors.gray_dark })
	highlight("PmenuThumb", { bg = colors.pink_soft })

	-- Messages and command line
	highlight("ModeMsg", { fg = colors.cyan_bright, style = "bold" })
	highlight("MoreMsg", { fg = colors.green, style = "bold" })
	highlight("ErrorMsg", { fg = colors.red, style = "bold" })
	highlight("WarningMsg", { fg = colors.yellow, style = "bold" })

	-- Folds
	highlight("Folded", { fg = colors.fg_dark, bg = colors.bg_light })
	highlight("FoldColumn", { fg = colors.gray, bg = colors.bg })

	-- Diffs
	highlight("DiffAdd", { fg = colors.green, bg = colors.bg })
	highlight("DiffChange", { fg = colors.yellow, bg = colors.bg })
	highlight("DiffDelete", { fg = colors.red, bg = colors.bg })
	highlight("DiffText", { fg = colors.cyan_bright, bg = colors.gray_dark })

	-- Spelling
	highlight("SpellBad", { sp = colors.red, style = "undercurl" })
	highlight("SpellCap", { sp = colors.blue, style = "undercurl" })
	highlight("SpellLocal", { sp = colors.cyan, style = "undercurl" })
	highlight("SpellRare", { sp = colors.purple, style = "undercurl" })

	-- Miscellaneous
	highlight("Directory", { fg = colors.cyan })
	highlight("Title", { fg = colors.pink_bright, style = "bold" })
	highlight("Question", { fg = colors.cyan_bright })
	highlight("NonText", { fg = colors.gray })
	highlight("SpecialKey", { fg = colors.gray })
	highlight("Whitespace", { fg = colors.gray_dark })

	-- Syntax highlighting
	highlight("Comment", { fg = colors.gray_light, style = "italic" })
	highlight("Constant", { fg = colors.cyan_soft })
	highlight("String", { fg = colors.green })
	highlight("Character", { fg = colors.orange })
	highlight("Number", { fg = colors.pink_soft })
	highlight("Boolean", { fg = colors.pink_soft })
	highlight("Float", { fg = colors.pink_soft })

	highlight("Identifier", { fg = colors.cyan })
	highlight("Function", { fg = colors.blue, style = "bold" })

	highlight("Statement", { fg = colors.magenta, style = "bold" })
	highlight("Conditional", { fg = colors.magenta })
	highlight("Repeat", { fg = colors.magenta })
	highlight("Label", { fg = colors.magenta })
	highlight("Operator", { fg = colors.pink })
	highlight("Keyword", { fg = colors.purple })
	highlight("Exception", { fg = colors.red })

	highlight("PreProc", { fg = colors.pink_bright })
	highlight("Include", { fg = colors.magenta })
	highlight("Define", { fg = colors.magenta })
	highlight("Macro", { fg = colors.pink_bright })
	highlight("PreCondit", { fg = colors.pink_soft })

	highlight("Type", { fg = colors.purple_deep })
	highlight("StorageClass", { fg = colors.purple_deep })
	highlight("Structure", { fg = colors.purple_deep })
	highlight("Typedef", { fg = colors.purple_deep })

	highlight("Special", { fg = colors.cyan_bright })
	highlight("SpecialChar", { fg = colors.cyan_bright })
	highlight("Tag", { fg = colors.pink_bright })
	highlight("Delimiter", { fg = colors.fg_alt })
	highlight("SpecialComment", { fg = colors.gray_light })
	highlight("Debug", { fg = colors.red })

	highlight("Underlined", { style = "underline" })
	highlight("Ignore", { fg = colors.gray })
	highlight("Error", { fg = colors.red, style = "bold" })
	highlight("Todo", { fg = colors.cyan_bright, bg = colors.bg, style = "bold" })

	-- Treesitter highlights
	highlight("@comment", { fg = colors.gray_light, style = "italic" })
	highlight("@comment.documentation", { fg = colors.gray_light, style = "italic" })

	highlight("@keyword", { fg = colors.purple })
	highlight("@keyword.function", { fg = colors.magenta })
	highlight("@keyword.operator", { fg = colors.pink })
	highlight("@keyword.return", { fg = colors.magenta })
	highlight("@keyword.conditional", { fg = colors.magenta })
	highlight("@keyword.repeat", { fg = colors.magenta })
	highlight("@keyword.import", { fg = colors.purple })

	highlight("@function", { fg = colors.blue })
	highlight("@function.builtin", { fg = colors.cyan })
	highlight("@function.call", { fg = colors.blue })
	highlight("@function.macro", { fg = colors.pink_bright })
	highlight("@method", { fg = colors.blue })
	highlight("@method.call", { fg = colors.blue })

	highlight("@variable", { fg = colors.fg })
	highlight("@variable.builtin", { fg = colors.cyan })
	highlight("@variable.parameter", { fg = colors.fg_alt })
	highlight("@variable.member", { fg = colors.cyan_soft })

	highlight("@string", { fg = colors.green })
	highlight("@string.documentation", { fg = colors.green })
	highlight("@string.regex", { fg = colors.pink_soft })
	highlight("@string.escape", { fg = colors.cyan_bright })

	highlight("@character", { fg = colors.orange })
	highlight("@character.special", { fg = colors.cyan_bright })

	highlight("@number", { fg = colors.pink_soft })
	highlight("@number.float", { fg = colors.pink_soft })
	highlight("@boolean", { fg = colors.pink_soft })

	highlight("@type", { fg = colors.purple_deep })
	highlight("@type.builtin", { fg = colors.purple })
	highlight("@type.definition", { fg = colors.purple_deep })

	highlight("@constant", { fg = colors.cyan_soft })
	highlight("@constant.builtin", { fg = colors.cyan })
	highlight("@constant.macro", { fg = colors.pink_bright })

	highlight("@constructor", { fg = colors.purple_deep })
	highlight("@namespace", { fg = colors.purple })
	highlight("@module", { fg = colors.purple })

	highlight("@operator", { fg = colors.pink })
	highlight("@punctuation.delimiter", { fg = colors.fg_alt })
	highlight("@punctuation.bracket", { fg = colors.pink_soft })
	highlight("@punctuation.special", { fg = colors.cyan_bright })

	highlight("@tag", { fg = colors.pink_bright })
	highlight("@tag.attribute", { fg = colors.cyan })
	highlight("@tag.delimiter", { fg = colors.fg_alt })

	highlight("@property", { fg = colors.cyan_soft })
	highlight("@field", { fg = colors.cyan_soft })

	highlight("@label", { fg = colors.magenta })

	-- LSP highlights
	highlight("DiagnosticError", { fg = colors.red })
	highlight("DiagnosticWarn", { fg = colors.yellow })
	highlight("DiagnosticInfo", { fg = colors.cyan })
	highlight("DiagnosticHint", { fg = colors.pink_soft })

	highlight("DiagnosticUnderlineError", { sp = colors.red, style = "undercurl" })
	highlight("DiagnosticUnderlineWarn", { sp = colors.yellow, style = "undercurl" })
	highlight("DiagnosticUnderlineInfo", { sp = colors.cyan, style = "undercurl" })
	highlight("DiagnosticUnderlineHint", { sp = colors.pink_soft, style = "undercurl" })

	highlight("LspReferenceText", { bg = colors.bg_light })
	highlight("LspReferenceRead", { bg = colors.bg_light })
	highlight("LspReferenceWrite", { bg = colors.bg_light })

	highlight("LspSignatureActiveParameter", { fg = colors.cyan_bright, style = "bold" })

	-- Git signs
	highlight("GitSignsAdd", { fg = colors.green })
	highlight("GitSignsChange", { fg = colors.yellow })
	highlight("GitSignsDelete", { fg = colors.red })

	-- Telescope
	highlight("TelescopeNormal", { fg = colors.fg, bg = colors.bg_float })
	highlight("TelescopeBorder", { fg = colors.pink_soft, bg = colors.bg_float })
	highlight("TelescopePromptBorder", { fg = colors.pink_bright, bg = colors.bg_float })
	highlight("TelescopeResultsBorder", { fg = colors.cyan_soft, bg = colors.bg_float })
	highlight("TelescopePreviewBorder", { fg = colors.purple, bg = colors.bg_float })

	highlight("TelescopeSelection", { fg = colors.fg_light, bg = colors.bg_light })
	highlight("TelescopeSelectionCaret", { fg = colors.pink_bright, bg = colors.bg_light })
	highlight("TelescopeMultiSelection", { fg = colors.cyan_bright, bg = colors.bg_light })

	highlight("TelescopeMatching", { fg = colors.pink_bright, style = "bold" })
	highlight("TelescopePromptPrefix", { fg = colors.cyan_bright })

	-- NvimTree
	highlight("NvimTreeNormal", { fg = colors.fg, bg = colors.bg_alt })
	highlight("NvimTreeWinSeparator", { fg = colors.pink_soft, bg = colors.bg_alt })
	highlight("NvimTreeRootFolder", { fg = colors.pink_bright, style = "bold" })
	highlight("NvimTreeFolderName", { fg = colors.cyan })
	highlight("NvimTreeFolderIcon", { fg = colors.cyan })
	highlight("NvimTreeOpenedFolderName", { fg = colors.cyan_bright })
	highlight("NvimTreeIndentMarker", { fg = colors.gray })
	highlight("NvimTreeGitDirty", { fg = colors.yellow })
	highlight("NvimTreeGitNew", { fg = colors.green })
	highlight("NvimTreeGitDeleted", { fg = colors.red })
	highlight("NvimTreeSpecialFile", { fg = colors.magenta })
	highlight("NvimTreeImageFile", { fg = colors.pink_soft })
	highlight("NvimTreeExecFile", { fg = colors.green })

	-- IndentBlankline
	highlight("IndentBlanklineChar", { fg = colors.gray_dark })
	highlight("IndentBlanklineContextChar", { fg = colors.pink_soft })
	highlight("IndentBlanklineContextStart", { sp = colors.pink_soft, style = "underline" })

	-- Which-key
	highlight("WhichKey", { fg = colors.pink_bright })
	highlight("WhichKeyGroup", { fg = colors.cyan })
	highlight("WhichKeyDesc", { fg = colors.fg })
	highlight("WhichKeySeperator", { fg = colors.gray })
	highlight("WhichKeyFloat", { bg = colors.bg_float })
	highlight("WhichKeyBorder", { fg = colors.pink_soft })

	-- BufferLine
	highlight("BufferLineIndicatorSelected", { fg = colors.pink_bright })
	highlight("BufferLineFill", { bg = colors.bg_statusline })

	-- Notify
	highlight("NotifyBackground", { bg = colors.bg_float })
	highlight("NotifyERRORBorder", { fg = colors.red })
	highlight("NotifyWARNBorder", { fg = colors.yellow })
	highlight("NotifyINFOBorder", { fg = colors.cyan })
	highlight("NotifyDEBUGBorder", { fg = colors.gray })
	highlight("NotifyTRACEBorder", { fg = colors.purple })

	-- CMP (completion)
	highlight("CmpItemAbbrDeprecated", { fg = colors.gray, style = "strikethrough" })
	highlight("CmpItemAbbrMatch", { fg = colors.pink_bright, style = "bold" })
	highlight("CmpItemAbbrMatchFuzzy", { fg = colors.pink_bright, style = "bold" })
	highlight("CmpItemKindVariable", { fg = colors.cyan })
	highlight("CmpItemKindInterface", { fg = colors.purple_deep })
	highlight("CmpItemKindText", { fg = colors.fg })
	highlight("CmpItemKindFunction", { fg = colors.blue })
	highlight("CmpItemKindMethod", { fg = colors.blue })
	highlight("CmpItemKindKeyword", { fg = colors.magenta })
	highlight("CmpItemKindProperty", { fg = colors.cyan_soft })
	highlight("CmpItemKindUnit", { fg = colors.fg })

	-- Markdown highlights
	highlight("markdownCode", { fg = colors.green, bg = colors.bg_lighter })
	highlight("markdownCodeBlock", { fg = colors.fg_alt, bg = colors.bg_lighter })
	highlight("markdownCodeDelimiter", { fg = colors.pink_soft, bg = colors.bg_lighter })
	highlight("markdownH1", { fg = colors.pink_bright, style = "bold" })
	highlight("markdownH2", { fg = colors.pink_bright, style = "bold" })
	highlight("markdownH3", { fg = colors.cyan, style = "bold" })
	highlight("markdownH4", { fg = colors.cyan })
	highlight("markdownH5", { fg = colors.purple })
	highlight("markdownH6", { fg = colors.purple })
	highlight("markdownHeadingDelimiter", { fg = colors.pink_bright, style = "bold" })
	highlight("markdownHeadingRule", { fg = colors.pink_bright, style = "bold" })
	highlight("markdownBold", { fg = colors.fg_light, style = "bold" })
	highlight("markdownItalic", { fg = colors.fg_light, style = "italic" })
	highlight("markdownBoldItalic", { fg = colors.fg_light, style = "bold,italic" })
	highlight("markdownUrl", { fg = colors.cyan_bright, style = "underline" })
	highlight("markdownLink", { fg = colors.pink_bright })
	highlight("markdownLinkText", { fg = colors.cyan })
	highlight("markdownLinkDelimiter", { fg = colors.gray })
	highlight("markdownLinkTextDelimiter", { fg = colors.gray })
	highlight("markdownListMarker", { fg = colors.magenta })
	highlight("markdownOrderedListMarker", { fg = colors.magenta })
	highlight("markdownRule", { fg = colors.pink_soft })
	highlight("markdownBlockquote", { fg = colors.gray_light, style = "italic" })

	-- Treesitter markdown highlights
	highlight("@markup.heading.1.markdown", { fg = colors.pink_bright, style = "bold" })
	highlight("@markup.heading.2.markdown", { fg = colors.pink_bright, style = "bold" })
	highlight("@markup.heading.3.markdown", { fg = colors.cyan, style = "bold" })
	highlight("@markup.heading.4.markdown", { fg = colors.cyan })
	highlight("@markup.heading.5.markdown", { fg = colors.purple })
	highlight("@markup.heading.6.markdown", { fg = colors.purple })
	highlight("@markup.strong.markdown_inline", { fg = colors.fg_light, style = "bold" })
	highlight("@markup.italic.markdown_inline", { fg = colors.fg_light, style = "italic" })
	highlight("@markup.raw.markdown_inline", { fg = colors.green, bg = colors.bg_lighter })
	highlight("@markup.raw.block.markdown", { fg = colors.fg_alt, bg = colors.bg_lighter })
	highlight("@markup.link.label.markdown_inline", { fg = colors.cyan })
	highlight("@markup.link.url.markdown_inline", { fg = colors.cyan_bright, style = "underline" })
	highlight("@markup.list.markdown", { fg = colors.magenta })
	highlight("@markup.quote.markdown", { fg = colors.gray_light, style = "italic" })

	-- Additional code block highlights
	highlight("htmlH1", { fg = colors.pink_bright, style = "bold" })
	highlight("htmlH2", { fg = colors.pink_bright, style = "bold" })
	highlight("htmlH3", { fg = colors.cyan, style = "bold" })
	highlight("htmlH4", { fg = colors.cyan })
	highlight("htmlH5", { fg = colors.purple })
	highlight("htmlH6", { fg = colors.purple })

	-- Fenced code blocks with language specification
	highlight("@markup.raw.delimiter.markdown", { fg = colors.pink_soft, bg = colors.bg_lighter })
	highlight("@markup.raw.language.markdown", { fg = colors.cyan_bright, bg = colors.bg_lighter })

	-- For vim-markdown plugin
	highlight("mkdCodeDelimiter", { fg = colors.pink_soft, bg = colors.bg_lighter })
	highlight("mkdCodeStart", { fg = colors.pink_soft, bg = colors.bg_lighter })
	highlight("mkdCodeEnd", { fg = colors.pink_soft, bg = colors.bg_lighter })
	highlight("mkdCode", { fg = colors.green, bg = colors.bg_lighter })
end

return M
