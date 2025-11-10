-- Forest Blue colorscheme for Neovim
-- Inspired by mystical blue forest with snow-covered ground

local M = {}

-- Color palette from the mystical blue forest image
local colors = {
	-- Core backgrounds
	bg = "none",         -- Deepest forest shadows (main background)
	bg_alt = "none",     -- Slightly lighter (floating windows, sidebars)
	bg_light = "#16213d", -- Lighter background (current line, selections)
	bg_lighter = "#1c2847", -- Lightest background (visual mode, folds)

	-- Special backgrounds
	bg_statusline = "#0a1020", -- Status line background
	bg_float = "#0f1830",   -- Floating window background

	-- Foreground colors
	fg = "#6ecfff",    -- Main text (bright blue-white from sky)
	fg_alt = "#5c7db8", -- Secondary text (muted foreground)
	fg_dark = "#2d4a7a", -- Darker text (comments, line numbers)
	fg_light = "#8da8e8", -- Light text (keywords, important elements)

	-- Primary syntax colors
	blue = "#4a73bf",    -- Keywords, types (mid-tone forest blue)
	light_blue = "#5c85d9", -- Functions, identifiers (brighter blue)
	dark_blue = "#2d4a80", -- Special elements (deeper blue)
	cyan = "#4d7aa6",    -- Constants, built-ins (blue-cyan)

	-- Complementary syntax colors
	purple = "#6b5cbf", -- Statements, control flow
	green = "#5ca673", -- Strings, success states
	yellow = "#7dcfff", -- Numbers, warnings
	orange = "#5dcfff", -- Characters, special chars
	red = "#5aafff", -- Errors, deletions

	-- UI element colors
	gray = "#3d4d73",    -- Borders, separators
	gray_light = "#4d5d8a", -- Light borders, inactive elements
	gray_dark = "#2d3d5c", -- Dark borders, disabled elements

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
	vim.g.colors_name = "forest_blue"

	-- Editor highlights
	highlight("Normal", { fg = colors.fg, bg = colors.bg })
	highlight("NormalFloat", { fg = colors.fg, bg = colors.bg_float })
	highlight("NormalNC", { fg = colors.fg_alt, bg = colors.bg })

	-- Cursor and selection
	highlight("Cursor", { fg = colors.bg, bg = colors.light_blue })
	highlight("CursorLine", { bg = colors.bg_light })
	highlight("CursorColumn", { bg = colors.bg_lighter })
	highlight("ColorColumn", { bg = colors.bg_lighter })
	highlight("Visual", { bg = colors.dark_blue })
	highlight("VisualNOS", { bg = colors.dark_blue })

	-- Line numbers
	highlight("LineNr", { fg = colors.gray })
	highlight("CursorLineNr", { fg = colors.light_blue, style = "bold" })
	highlight("SignColumn", { fg = colors.gray, bg = colors.bg })

	-- Search and matching
	highlight("Search", { fg = colors.bg, bg = colors.yellow })
	highlight("IncSearch", { fg = colors.bg, bg = colors.orange })
	highlight("MatchParen", { fg = colors.light_blue, style = "bold" })

	-- Splits and windows
	highlight("VertSplit", { fg = colors.gray_dark, bg = colors.bg })
	highlight("WinSeparator", { fg = colors.gray_dark, bg = colors.bg })
	highlight("StatusLine", { fg = colors.fg, bg = colors.bg_light })
	highlight("StatusLineNC", { fg = colors.fg_dark, bg = colors.bg_statusline })

	-- Tabs
	highlight("TabLine", { fg = colors.fg_dark, bg = colors.bg_light })
	highlight("TabLineSel", { fg = colors.fg_light, bg = colors.blue })
	highlight("TabLineFill", { bg = colors.bg_light })

	-- Popup menu
	highlight("Pmenu", { fg = colors.fg, bg = colors.bg_alt })
	highlight("PmenuSel", { fg = colors.fg_light, bg = colors.dark_blue })
	highlight("PmenuSbar", { bg = colors.gray_dark })
	highlight("PmenuThumb", { bg = colors.gray })

	-- Messages and command line
	highlight("ModeMsg", { fg = colors.light_blue, style = "bold" })
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
	highlight("DiffText", { fg = colors.yellow, bg = colors.gray_dark })

	-- Spelling
	highlight("SpellBad", { sp = colors.red, style = "undercurl" })
	highlight("SpellCap", { sp = colors.blue, style = "undercurl" })
	highlight("SpellLocal", { sp = colors.cyan, style = "undercurl" })
	highlight("SpellRare", { sp = colors.purple, style = "undercurl" })

	-- Miscellaneous
	highlight("Directory", { fg = colors.blue })
	highlight("Title", { fg = colors.light_blue, style = "bold" })
	highlight("Question", { fg = colors.green })
	highlight("NonText", { fg = colors.gray })
	highlight("SpecialKey", { fg = colors.gray })
	highlight("Whitespace", { fg = colors.gray_dark })

	-- Syntax highlighting
	highlight("Comment", { fg = colors.gray, style = "italic" })
	highlight("Constant", { fg = colors.cyan })
	highlight("String", { fg = colors.green })
	highlight("Character", { fg = colors.orange })
	highlight("Number", { fg = colors.yellow })
	highlight("Boolean", { fg = colors.yellow })
	highlight("Float", { fg = colors.yellow })

	highlight("Identifier", { fg = colors.light_blue })
	highlight("Function", { fg = colors.blue, style = "bold" })

	highlight("Statement", { fg = colors.purple, style = "bold" })
	highlight("Conditional", { fg = colors.purple })
	highlight("Repeat", { fg = colors.purple })
	highlight("Label", { fg = colors.purple })
	highlight("Operator", { fg = colors.fg })
	highlight("Keyword", { fg = colors.purple })
	highlight("Exception", { fg = colors.red })

	highlight("PreProc", { fg = colors.yellow })
	highlight("Include", { fg = colors.purple })
	highlight("Define", { fg = colors.purple })
	highlight("Macro", { fg = colors.red })
	highlight("PreCondit", { fg = colors.yellow })

	highlight("Type", { fg = colors.light_blue })
	highlight("StorageClass", { fg = colors.light_blue })
	highlight("Structure", { fg = colors.light_blue })
	highlight("Typedef", { fg = colors.light_blue })

	highlight("Special", { fg = colors.orange })
	highlight("SpecialChar", { fg = colors.orange })
	highlight("Tag", { fg = colors.red })
	highlight("Delimiter", { fg = colors.fg_alt })
	highlight("SpecialComment", { fg = colors.gray })
	highlight("Debug", { fg = colors.red })

	highlight("Underlined", { style = "underline" })
	highlight("Ignore", { fg = colors.gray })
	highlight("Error", { fg = colors.red, style = "bold" })
	highlight("Todo", { fg = colors.yellow, bg = colors.bg, style = "bold" })

	-- Treesitter highlights
	highlight("@comment", { fg = colors.gray, style = "italic" })
	highlight("@comment.documentation", { fg = colors.gray, style = "italic" })

	highlight("@keyword", { fg = colors.purple })
	highlight("@keyword.function", { fg = colors.purple })
	highlight("@keyword.operator", { fg = colors.purple })
	highlight("@keyword.return", { fg = colors.purple })
	highlight("@keyword.conditional", { fg = colors.purple })
	highlight("@keyword.repeat", { fg = colors.purple })
	highlight("@keyword.import", { fg = colors.purple })

	highlight("@function", { fg = colors.blue })
	highlight("@function.builtin", { fg = colors.blue })
	highlight("@function.call", { fg = colors.blue })
	highlight("@function.macro", { fg = colors.red })
	highlight("@method", { fg = colors.blue })
	highlight("@method.call", { fg = colors.blue })

	highlight("@variable", { fg = colors.fg })
	highlight("@variable.builtin", { fg = colors.light_blue })
	highlight("@variable.parameter", { fg = colors.fg_alt })
	highlight("@variable.member", { fg = colors.fg_alt })

	highlight("@string", { fg = colors.green })
	highlight("@string.documentation", { fg = colors.green })
	highlight("@string.regex", { fg = colors.green })
	highlight("@string.escape", { fg = colors.orange })

	highlight("@character", { fg = colors.orange })
	highlight("@character.special", { fg = colors.orange })

	highlight("@number", { fg = colors.yellow })
	highlight("@number.float", { fg = colors.yellow })
	highlight("@boolean", { fg = colors.yellow })

	highlight("@type", { fg = colors.light_blue })
	highlight("@type.builtin", { fg = colors.light_blue })
	highlight("@type.definition", { fg = colors.light_blue })

	highlight("@constant", { fg = colors.cyan })
	highlight("@constant.builtin", { fg = colors.cyan })
	highlight("@constant.macro", { fg = colors.cyan })

	highlight("@constructor", { fg = colors.light_blue })
	highlight("@namespace", { fg = colors.light_blue })
	highlight("@module", { fg = colors.light_blue })

	highlight("@operator", { fg = colors.fg })
	highlight("@punctuation.delimiter", { fg = colors.fg_alt })
	highlight("@punctuation.bracket", { fg = colors.fg_alt })
	highlight("@punctuation.special", { fg = colors.orange })

	highlight("@tag", { fg = colors.red })
	highlight("@tag.attribute", { fg = colors.light_blue })
	highlight("@tag.delimiter", { fg = colors.fg_alt })

	highlight("@property", { fg = colors.fg_alt })
	highlight("@field", { fg = colors.fg_alt })

	highlight("@label", { fg = colors.purple })

	-- LSP highlights
	highlight("DiagnosticError", { fg = colors.red })
	highlight("DiagnosticWarn", { fg = colors.yellow })
	highlight("DiagnosticInfo", { fg = colors.blue })
	highlight("DiagnosticHint", { fg = colors.cyan })

	highlight("DiagnosticUnderlineError", { sp = colors.red, style = "undercurl" })
	highlight("DiagnosticUnderlineWarn", { sp = colors.yellow, style = "undercurl" })
	highlight("DiagnosticUnderlineInfo", { sp = colors.blue, style = "undercurl" })
	highlight("DiagnosticUnderlineHint", { sp = colors.cyan, style = "undercurl" })

	highlight("LspReferenceText", { bg = colors.bg_light })
	highlight("LspReferenceRead", { bg = colors.bg_light })
	highlight("LspReferenceWrite", { bg = colors.bg_light })

	highlight("LspSignatureActiveParameter", { fg = colors.fg_light, style = "bold" })

	-- Git signs
	highlight("GitSignsAdd", { fg = colors.green })
	highlight("GitSignsChange", { fg = colors.yellow })
	highlight("GitSignsDelete", { fg = colors.red })

	-- Telescope
	highlight("TelescopeNormal", { fg = colors.fg, bg = colors.bg_float })
	highlight("TelescopeBorder", { fg = colors.gray, bg = colors.bg_float })
	highlight("TelescopePromptBorder", { fg = colors.gray, bg = colors.bg_float })
	highlight("TelescopeResultsBorder", { fg = colors.gray, bg = colors.bg_float })
	highlight("TelescopePreviewBorder", { fg = colors.gray, bg = colors.bg_float })

	highlight("TelescopeSelection", { fg = colors.fg, bg = colors.bg_light })
	highlight("TelescopeSelectionCaret", { fg = colors.light_blue, bg = colors.bg_light })
	highlight("TelescopeMultiSelection", { fg = colors.purple, bg = colors.bg_light })

	highlight("TelescopeMatching", { fg = colors.light_blue, style = "bold" })
	highlight("TelescopePromptPrefix", { fg = colors.red })

	-- NvimTree
	highlight("NvimTreeNormal", { fg = colors.fg, bg = colors.bg_alt })
	highlight("NvimTreeWinSeparator", { fg = colors.gray_dark, bg = colors.bg_alt })
	highlight("NvimTreeRootFolder", { fg = colors.light_blue, style = "bold" })
	highlight("NvimTreeFolderName", { fg = colors.blue })
	highlight("NvimTreeFolderIcon", { fg = colors.blue })
	highlight("NvimTreeOpenedFolderName", { fg = colors.light_blue })
	highlight("NvimTreeIndentMarker", { fg = colors.gray })
	highlight("NvimTreeGitDirty", { fg = colors.yellow })
	highlight("NvimTreeGitNew", { fg = colors.green })
	highlight("NvimTreeGitDeleted", { fg = colors.red })
	highlight("NvimTreeSpecialFile", { fg = colors.purple })
	highlight("NvimTreeImageFile", { fg = colors.purple })
	highlight("NvimTreeExecFile", { fg = colors.green })

	-- IndentBlankline
	highlight("IndentBlanklineChar", { fg = colors.gray_dark })
	highlight("IndentBlanklineContextChar", { fg = colors.gray })
	highlight("IndentBlanklineContextStart", { sp = colors.gray, style = "underline" })

	-- Which-key
	highlight("WhichKey", { fg = colors.light_blue })
	highlight("WhichKeyGroup", { fg = colors.purple })
	highlight("WhichKeyDesc", { fg = colors.fg })
	highlight("WhichKeySeperator", { fg = colors.gray })
	highlight("WhichKeyFloat", { bg = colors.bg_float })
	highlight("WhichKeyBorder", { fg = colors.gray })

	-- BufferLine
	highlight("BufferLineIndicatorSelected", { fg = colors.light_blue })
	highlight("BufferLineFill", { bg = colors.bg_statusline })

	-- Notify
	highlight("NotifyBackground", { bg = colors.bg_float })
	highlight("NotifyERRORBorder", { fg = colors.red })
	highlight("NotifyWARNBorder", { fg = colors.yellow })
	highlight("NotifyINFOBorder", { fg = colors.blue })
	highlight("NotifyDEBUGBorder", { fg = colors.gray })
	highlight("NotifyTRACEBorder", { fg = colors.purple })

	-- CMP (completion)
	highlight("CmpItemAbbrDeprecated", { fg = colors.gray, style = "strikethrough" })
	highlight("CmpItemAbbrMatch", { fg = colors.light_blue, style = "bold" })
	highlight("CmpItemAbbrMatchFuzzy", { fg = colors.light_blue, style = "bold" })
	highlight("CmpItemKindVariable", { fg = colors.cyan })
	highlight("CmpItemKindInterface", { fg = colors.cyan })
	highlight("CmpItemKindText", { fg = colors.cyan })
	highlight("CmpItemKindFunction", { fg = colors.purple })
	highlight("CmpItemKindMethod", { fg = colors.purple })
	highlight("CmpItemKindKeyword", { fg = colors.fg })
	highlight("CmpItemKindProperty", { fg = colors.fg })
	highlight("CmpItemKindUnit", { fg = colors.fg })

	-- Markdown highlights
	highlight("markdownCode", { fg = colors.green, bg = colors.bg_lighter })
	highlight("markdownCodeBlock", { fg = colors.fg_alt, bg = colors.bg_lighter })
	highlight("markdownCodeDelimiter", { fg = colors.gray, bg = colors.bg_lighter })
	highlight("markdownH1", { fg = colors.light_blue, style = "bold" })
	highlight("markdownH2", { fg = colors.light_blue, style = "bold" })
	highlight("markdownH3", { fg = colors.blue, style = "bold" })
	highlight("markdownH4", { fg = colors.blue })
	highlight("markdownH5", { fg = colors.blue })
	highlight("markdownH6", { fg = colors.blue })
	highlight("markdownHeadingDelimiter", { fg = colors.light_blue, style = "bold" })
	highlight("markdownHeadingRule", { fg = colors.light_blue, style = "bold" })
	highlight("markdownBold", { fg = colors.fg_light, style = "bold" })
	highlight("markdownItalic", { fg = colors.fg_light, style = "italic" })
	highlight("markdownBoldItalic", { fg = colors.fg_light, style = "bold,italic" })
	highlight("markdownUrl", { fg = colors.cyan, style = "underline" })
	highlight("markdownLink", { fg = colors.light_blue })
	highlight("markdownLinkText", { fg = colors.light_blue })
	highlight("markdownLinkDelimiter", { fg = colors.gray })
	highlight("markdownLinkTextDelimiter", { fg = colors.gray })
	highlight("markdownListMarker", { fg = colors.purple })
	highlight("markdownOrderedListMarker", { fg = colors.purple })
	highlight("markdownRule", { fg = colors.gray })
	highlight("markdownBlockquote", { fg = colors.gray, style = "italic" })

	-- Treesitter markdown highlights (for newer Neovim versions)
	highlight("@markup.heading.1.markdown", { fg = colors.light_blue, style = "bold" })
	highlight("@markup.heading.2.markdown", { fg = colors.light_blue, style = "bold" })
	highlight("@markup.heading.3.markdown", { fg = colors.blue, style = "bold" })
	highlight("@markup.heading.4.markdown", { fg = colors.blue })
	highlight("@markup.heading.5.markdown", { fg = colors.blue })
	highlight("@markup.heading.6.markdown", { fg = colors.blue })
	highlight("@markup.strong.markdown_inline", { fg = colors.fg_light, style = "bold" })
	highlight("@markup.italic.markdown_inline", { fg = colors.fg_light, style = "italic" })
	highlight("@markup.raw.markdown_inline", { fg = colors.green, bg = colors.bg_lighter })
	highlight("@markup.raw.block.markdown", { fg = colors.fg_alt, bg = colors.bg_lighter })
	highlight("@markup.link.label.markdown_inline", { fg = colors.light_blue })
	highlight("@markup.link.url.markdown_inline", { fg = colors.cyan, style = "underline" })
	highlight("@markup.list.markdown", { fg = colors.purple })
	highlight("@markup.quote.markdown", { fg = colors.gray, style = "italic" })

	-- Additional code block highlights for different markdown parsers
	highlight("htmlH1", { fg = colors.light_blue, style = "bold" })
	highlight("htmlH2", { fg = colors.light_blue, style = "bold" })
	highlight("htmlH3", { fg = colors.blue, style = "bold" })
	highlight("htmlH4", { fg = colors.blue })
	highlight("htmlH5", { fg = colors.blue })
	highlight("htmlH6", { fg = colors.blue })

	-- Fenced code blocks with language specification
	highlight("@markup.raw.delimiter.markdown", { fg = colors.gray, bg = colors.bg_lighter })
	highlight("@markup.raw.language.markdown", { fg = colors.yellow, bg = colors.bg_lighter })

	-- For vim-markdown plugin
	highlight("mkdCodeDelimiter", { fg = colors.gray, bg = colors.bg_lighter })
	highlight("mkdCodeStart", { fg = colors.gray, bg = colors.bg_lighter })
	highlight("mkdCodeEnd", { fg = colors.gray, bg = colors.bg_lighter })
	highlight("mkdCode", { fg = colors.green, bg = colors.bg_lighter })
end

return M
