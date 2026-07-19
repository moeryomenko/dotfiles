-- VHS Purple colorscheme for Neovim
-- Inspired by VHS tapes and retro purple aesthetics with grainy noise effects

local M = {}

-- Color palette from VHS purple aesthetic
local colors = {
	-- Base colors from the images
	bg = "#0a0a0f", -- Deep black background
	bg_alt = "#12121a", -- Slightly lighter bg
	bg_highlight = "#1a1a28", -- Highlighted bg

	fg = "#b8b4d4", -- Main purple-tinted text
	fg_dim = "#8884a8", -- Dimmed text
	fg_bright = "#d4d0f0", -- Bright text

	-- Purple tones (dominant in the images)
	purple = "#8884d8", -- Main purple
	purple_dim = "#6864a8", -- Dim purple
	purple_bright = "#a8a4f8", -- Bright purple

	-- Blue tones (secondary)
	blue = "#6878c8", -- Blue accent
	blue_dim = "#485890", -- Dim blue
	cyan = "#78a8d8", -- Cyan accent

	-- Accent colors
	pink = "#c888b8", -- Pink accent
	lavender = "#a888d8", -- Lavender

	-- Grayscale (VHS noise effect)
	gray = "#484858", -- Medium gray
	gray_dim = "#282838", -- Dark gray
	gray_bright = "#686878", -- Light gray

	-- UI elements
	comment = "#585868", -- Comments
	selection = "#282840", -- Visual selection
	visual = "#38384f", -- Visual mode

	-- Status colors
	error = "#d88888", -- Errors
	warning = "#d8c888", -- Warnings
	info = "#88c8d8", -- Info
	hint = "#b888d8", -- Hints
	success = "#88d8b8", -- Success

	-- Special
	cursor = "#c8c4e8", -- Cursor
	line_nr = "#484860", -- Line numbers
	border = "#383848", -- Borders

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
	vim.g.colors_name = "vhs_purple"

	-- Editor highlights
	highlight("Normal", { fg = colors.fg, bg = colors.bg })
	highlight("NormalFloat", { fg = colors.fg, bg = colors.bg_alt })
	highlight("NormalNC", { fg = colors.fg_dim, bg = colors.bg })

	-- Cursor and selection
	highlight("Cursor", { fg = colors.bg, bg = colors.cursor })
	highlight("CursorLine", { bg = colors.bg_highlight })
	highlight("CursorColumn", { bg = colors.bg_highlight })
	highlight("ColorColumn", { bg = colors.bg_highlight })
	highlight("Visual", { bg = colors.visual })
	highlight("VisualNOS", { bg = colors.visual })

	-- Line numbers
	highlight("LineNr", { fg = colors.line_nr })
	highlight("CursorLineNr", { fg = colors.purple, style = "bold" })
	highlight("SignColumn", { fg = colors.gray, bg = colors.bg })

	-- Search and matching
	highlight("Search", { fg = colors.bg, bg = colors.warning })
	highlight("IncSearch", { fg = colors.bg, bg = colors.pink })
	highlight("MatchParen", { fg = colors.purple_bright, style = "bold" })

	-- Splits and windows
	highlight("VertSplit", { fg = colors.border, bg = colors.bg })
	highlight("WinSeparator", { fg = colors.border, bg = colors.bg })
	highlight("StatusLine", { fg = colors.fg, bg = colors.bg_highlight })
	highlight("StatusLineNC", { fg = colors.fg_dim, bg = colors.bg_alt })

	-- Tabs
	highlight("TabLine", { fg = colors.fg_dim, bg = colors.bg_highlight })
	highlight("TabLineSel", { fg = colors.fg_bright, bg = colors.purple })
	highlight("TabLineFill", { bg = colors.bg_highlight })

	-- Popup menu
	highlight("Pmenu", { fg = colors.fg, bg = colors.bg_alt })
	highlight("PmenuSel", { fg = colors.fg_bright, bg = colors.purple_dim })
	highlight("PmenuSbar", { bg = colors.gray_dim })
	highlight("PmenuThumb", { bg = colors.gray })

	-- Messages and command line
	highlight("ModeMsg", { fg = colors.purple, style = "bold" })
	highlight("MoreMsg", { fg = colors.success, style = "bold" })
	highlight("ErrorMsg", { fg = colors.error, style = "bold" })
	highlight("WarningMsg", { fg = colors.warning, style = "bold" })

	-- Folds
	highlight("Folded", { fg = colors.fg_dim, bg = colors.bg_highlight })
	highlight("FoldColumn", { fg = colors.gray, bg = colors.bg })

	-- Diffs
	highlight("DiffAdd", { fg = colors.success, bg = colors.bg })
	highlight("DiffChange", { fg = colors.warning, bg = colors.bg })
	highlight("DiffDelete", { fg = colors.error, bg = colors.bg })
	highlight("DiffText", { fg = colors.warning, bg = colors.gray_dim })

	-- Spelling
	highlight("SpellBad", { sp = colors.error, style = "undercurl" })
	highlight("SpellCap", { sp = colors.blue, style = "undercurl" })
	highlight("SpellLocal", { sp = colors.cyan, style = "undercurl" })
	highlight("SpellRare", { sp = colors.purple, style = "undercurl" })

	-- Miscellaneous
	highlight("Directory", { fg = colors.blue })
	highlight("Title", { fg = colors.purple, style = "bold" })
	highlight("Question", { fg = colors.success })
	highlight("NonText", { fg = colors.gray })
	highlight("SpecialKey", { fg = colors.gray })
	highlight("Whitespace", { fg = colors.gray_dim })

	-- Syntax highlighting
	highlight("Comment", { fg = colors.comment, style = "italic" })
	highlight("Constant", { fg = colors.cyan })
	highlight("String", { fg = colors.success })
	highlight("Character", { fg = colors.pink })
	highlight("Number", { fg = colors.lavender })
	highlight("Boolean", { fg = colors.lavender })
	highlight("Float", { fg = colors.lavender })

	highlight("Identifier", { fg = colors.purple })
	highlight("Function", { fg = colors.blue, style = "bold" })

	highlight("Statement", { fg = colors.purple, style = "bold" })
	highlight("Conditional", { fg = colors.purple })
	highlight("Repeat", { fg = colors.purple })
	highlight("Label", { fg = colors.purple })
	highlight("Operator", { fg = colors.fg })
	highlight("Keyword", { fg = colors.purple })
	highlight("Exception", { fg = colors.error })

	highlight("PreProc", { fg = colors.lavender })
	highlight("Include", { fg = colors.purple })
	highlight("Define", { fg = colors.purple })
	highlight("Macro", { fg = colors.pink })
	highlight("PreCondit", { fg = colors.lavender })

	highlight("Type", { fg = colors.purple_bright })
	highlight("StorageClass", { fg = colors.purple_bright })
	highlight("Structure", { fg = colors.purple_bright })
	highlight("Typedef", { fg = colors.purple_bright })

	highlight("Special", { fg = colors.pink })
	highlight("SpecialChar", { fg = colors.pink })
	highlight("Tag", { fg = colors.pink })
	highlight("Delimiter", { fg = colors.fg_dim })
	highlight("SpecialComment", { fg = colors.comment })
	highlight("Debug", { fg = colors.error })

	highlight("Underlined", { style = "underline" })
	highlight("Ignore", { fg = colors.gray })
	highlight("Error", { fg = colors.error, style = "bold" })
	highlight("Todo", { fg = colors.warning, bg = colors.bg, style = "bold" })

	-- Treesitter highlights
	highlight("@comment", { fg = colors.comment, style = "italic" })
	highlight("@comment.documentation", { fg = colors.comment, style = "italic" })

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
	highlight("@function.macro", { fg = colors.pink })
	highlight("@method", { fg = colors.blue })
	highlight("@method.call", { fg = colors.blue })

	highlight("@variable", { fg = colors.fg })
	highlight("@variable.builtin", { fg = colors.purple })
	highlight("@variable.parameter", { fg = colors.fg_dim })
	highlight("@variable.member", { fg = colors.fg_dim })

	highlight("@string", { fg = colors.success })
	highlight("@string.documentation", { fg = colors.success })
	highlight("@string.regex", { fg = colors.success })
	highlight("@string.escape", { fg = colors.pink })

	highlight("@character", { fg = colors.pink })
	highlight("@character.special", { fg = colors.pink })

	highlight("@number", { fg = colors.lavender })
	highlight("@number.float", { fg = colors.lavender })
	highlight("@boolean", { fg = colors.lavender })

	highlight("@type", { fg = colors.purple_bright })
	highlight("@type.builtin", { fg = colors.purple_bright })
	highlight("@type.definition", { fg = colors.purple_bright })

	highlight("@constant", { fg = colors.cyan })
	highlight("@constant.builtin", { fg = colors.cyan })
	highlight("@constant.macro", { fg = colors.cyan })

	highlight("@constructor", { fg = colors.purple_bright })
	highlight("@namespace", { fg = colors.purple_bright })
	highlight("@module", { fg = colors.purple_bright })

	highlight("@operator", { fg = colors.fg })
	highlight("@punctuation.delimiter", { fg = colors.fg_dim })
	highlight("@punctuation.bracket", { fg = colors.fg_dim })
	highlight("@punctuation.special", { fg = colors.pink })

	highlight("@tag", { fg = colors.pink })
	highlight("@tag.attribute", { fg = colors.purple })
	highlight("@tag.delimiter", { fg = colors.fg_dim })

	highlight("@property", { fg = colors.fg_dim })
	highlight("@field", { fg = colors.fg_dim })

	highlight("@label", { fg = colors.purple })

	-- LSP highlights
	highlight("DiagnosticError", { fg = colors.error })
	highlight("DiagnosticWarn", { fg = colors.warning })
	highlight("DiagnosticInfo", { fg = colors.info })
	highlight("DiagnosticHint", { fg = colors.hint })

	highlight("DiagnosticUnderlineError", { sp = colors.error, style = "undercurl" })
	highlight("DiagnosticUnderlineWarn", { sp = colors.warning, style = "undercurl" })
	highlight("DiagnosticUnderlineInfo", { sp = colors.info, style = "undercurl" })
	highlight("DiagnosticUnderlineHint", { sp = colors.hint, style = "undercurl" })

	highlight("LspReferenceText", { bg = colors.bg_highlight })
	highlight("LspReferenceRead", { bg = colors.bg_highlight })
	highlight("LspReferenceWrite", { bg = colors.bg_highlight })

	highlight("LspSignatureActiveParameter", { fg = colors.fg_bright, style = "bold" })

	-- Git signs
	highlight("GitSignsAdd", { fg = colors.success })
	highlight("GitSignsChange", { fg = colors.warning })
	highlight("GitSignsDelete", { fg = colors.error })

	-- Telescope
	highlight("TelescopeNormal", { fg = colors.fg, bg = colors.bg_alt })
	highlight("TelescopeBorder", { fg = colors.border, bg = colors.bg_alt })
	highlight("TelescopePromptBorder", { fg = colors.border, bg = colors.bg_alt })
	highlight("TelescopeResultsBorder", { fg = colors.border, bg = colors.bg_alt })
	highlight("TelescopePreviewBorder", { fg = colors.border, bg = colors.bg_alt })

	highlight("TelescopeSelection", { fg = colors.fg, bg = colors.bg_highlight })
	highlight("TelescopeSelectionCaret", { fg = colors.purple, bg = colors.bg_highlight })
	highlight("TelescopeMultiSelection", { fg = colors.purple, bg = colors.bg_highlight })

	highlight("TelescopeMatching", { fg = colors.purple_bright, style = "bold" })
	highlight("TelescopePromptPrefix", { fg = colors.pink })

	-- NvimTree
	highlight("NvimTreeNormal", { fg = colors.fg, bg = colors.bg_alt })
	highlight("NvimTreeWinSeparator", { fg = colors.border, bg = colors.bg_alt })
	highlight("NvimTreeRootFolder", { fg = colors.purple, style = "bold" })
	highlight("NvimTreeFolderName", { fg = colors.blue })
	highlight("NvimTreeFolderIcon", { fg = colors.blue })
	highlight("NvimTreeOpenedFolderName", { fg = colors.purple })
	highlight("NvimTreeIndentMarker", { fg = colors.gray })
	highlight("NvimTreeGitDirty", { fg = colors.warning })
	highlight("NvimTreeGitNew", { fg = colors.success })
	highlight("NvimTreeGitDeleted", { fg = colors.error })
	highlight("NvimTreeSpecialFile", { fg = colors.purple })
	highlight("NvimTreeImageFile", { fg = colors.pink })
	highlight("NvimTreeExecFile", { fg = colors.success })

	-- IndentBlankline
	highlight("IndentBlanklineChar", { fg = colors.gray_dim })
	highlight("IndentBlanklineContextChar", { fg = colors.gray })
	highlight("IndentBlanklineContextStart", { sp = colors.gray, style = "underline" })

	-- Which-key
	highlight("WhichKey", { fg = colors.purple })
	highlight("WhichKeyGroup", { fg = colors.purple_bright })
	highlight("WhichKeyDesc", { fg = colors.fg })
	highlight("WhichKeySeperator", { fg = colors.gray })
	highlight("WhichKeyFloat", { bg = colors.bg_alt })
	highlight("WhichKeyBorder", { fg = colors.border })

	-- BufferLine
	highlight("BufferLineIndicatorSelected", { fg = colors.purple })
	highlight("BufferLineFill", { bg = colors.bg_alt })

	-- Notify
	highlight("NotifyBackground", { bg = colors.bg_alt })
	highlight("NotifyERRORBorder", { fg = colors.error })
	highlight("NotifyWARNBorder", { fg = colors.warning })
	highlight("NotifyINFOBorder", { fg = colors.info })
	highlight("NotifyDEBUGBorder", { fg = colors.gray })
	highlight("NotifyTRACEBorder", { fg = colors.purple })

	-- CMP (completion)
	highlight("CmpItemAbbrDeprecated", { fg = colors.gray, style = "strikethrough" })
	highlight("CmpItemAbbrMatch", { fg = colors.purple_bright, style = "bold" })
	highlight("CmpItemAbbrMatchFuzzy", { fg = colors.purple_bright, style = "bold" })
	highlight("CmpItemKindVariable", { fg = colors.cyan })
	highlight("CmpItemKindInterface", { fg = colors.cyan })
	highlight("CmpItemKindText", { fg = colors.cyan })
	highlight("CmpItemKindFunction", { fg = colors.purple })
	highlight("CmpItemKindMethod", { fg = colors.purple })
	highlight("CmpItemKindKeyword", { fg = colors.fg })
	highlight("CmpItemKindProperty", { fg = colors.fg })
	highlight("CmpItemKindUnit", { fg = colors.fg })

	-- Markdown highlights
	highlight("markdownCode", { fg = colors.success, bg = colors.bg_highlight })
	highlight("markdownCodeBlock", { fg = colors.fg_dim, bg = colors.bg_highlight })
	highlight("markdownCodeDelimiter", { fg = colors.gray, bg = colors.bg_highlight })
	highlight("markdownH1", { fg = colors.purple_bright, style = "bold" })
	highlight("markdownH2", { fg = colors.purple_bright, style = "bold" })
	highlight("markdownH3", { fg = colors.purple, style = "bold" })
	highlight("markdownH4", { fg = colors.purple })
	highlight("markdownH5", { fg = colors.purple })
	highlight("markdownH6", { fg = colors.purple })
	highlight("markdownHeadingDelimiter", { fg = colors.purple_bright, style = "bold" })
	highlight("markdownHeadingRule", { fg = colors.purple_bright, style = "bold" })
	highlight("markdownBold", { fg = colors.fg_bright, style = "bold" })
	highlight("markdownItalic", { fg = colors.fg_bright, style = "italic" })
	highlight("markdownBoldItalic", { fg = colors.fg_bright, style = "bold,italic" })
	highlight("markdownUrl", { fg = colors.cyan, style = "underline" })
	highlight("markdownLink", { fg = colors.purple })
	highlight("markdownLinkText", { fg = colors.purple })
	highlight("markdownLinkDelimiter", { fg = colors.gray })
	highlight("markdownLinkTextDelimiter", { fg = colors.gray })
	highlight("markdownListMarker", { fg = colors.lavender })
	highlight("markdownOrderedListMarker", { fg = colors.lavender })
	highlight("markdownRule", { fg = colors.gray })
	highlight("markdownBlockquote", { fg = colors.gray, style = "italic" })

	-- Treesitter markdown highlights (for newer Neovim versions)
	highlight("@markup.heading.1.markdown", { fg = colors.purple_bright, style = "bold" })
	highlight("@markup.heading.2.markdown", { fg = colors.purple_bright, style = "bold" })
	highlight("@markup.heading.3.markdown", { fg = colors.purple, style = "bold" })
	highlight("@markup.heading.4.markdown", { fg = colors.purple })
	highlight("@markup.heading.5.markdown", { fg = colors.purple })
	highlight("@markup.heading.6.markdown", { fg = colors.purple })
	highlight("@markup.strong.markdown_inline", { fg = colors.fg_bright, style = "bold" })
	highlight("@markup.italic.markdown_inline", { fg = colors.fg_bright, style = "italic" })
	highlight("@markup.raw.markdown_inline", { fg = colors.success, bg = colors.bg_highlight })
	highlight("@markup.raw.block.markdown", { fg = colors.fg_dim, bg = colors.bg_highlight })
	highlight("@markup.link.label.markdown_inline", { fg = colors.purple })
	highlight("@markup.link.url.markdown_inline", { fg = colors.cyan, style = "underline" })
	highlight("@markup.list.markdown", { fg = colors.lavender })
	highlight("@markup.quote.markdown", { fg = colors.gray, style = "italic" })

	-- Additional code block highlights for different markdown parsers
	highlight("htmlH1", { fg = colors.purple_bright, style = "bold" })
	highlight("htmlH2", { fg = colors.purple_bright, style = "bold" })
	highlight("htmlH3", { fg = colors.purple, style = "bold" })
	highlight("htmlH4", { fg = colors.purple })
	highlight("htmlH5", { fg = colors.purple })
	highlight("htmlH6", { fg = colors.purple })

	-- Fenced code blocks with language specification
	highlight("@markup.raw.delimiter.markdown", { fg = colors.gray, bg = colors.bg_highlight })
	highlight("@markup.raw.language.markdown", { fg = colors.lavender, bg = colors.bg_highlight })

	-- For vim-markdown plugin
	highlight("mkdCodeDelimiter", { fg = colors.gray, bg = colors.bg_highlight })
	highlight("mkdCodeStart", { fg = colors.gray, bg = colors.bg_highlight })
	highlight("mkdCodeEnd", { fg = colors.gray, bg = colors.bg_highlight })
	highlight("mkdCode", { fg = colors.success, bg = colors.bg_highlight })
end

return M
