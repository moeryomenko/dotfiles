-- Neon Dreams colorscheme for Neovim
-- Inspired by cyberpunk neon aesthetics with vibrant pinks, purples, and blues

local M = {}

-- Color palette extracted from the neon cyberpunk images
local colors = {
	-- Core backgrounds
	bg = "#0a0515",      -- Deep purple-black (main background)
	bg_alt = "#120820",  -- Slightly lighter purple-black (floating windows, sidebars)
	bg_light = "#1a0f2e", -- Lighter background (current line, selections)
	bg_lighter = "#221638", -- Lightest background (visual mode, folds)

	-- Special backgrounds
	bg_statusline = "#0d0618", -- Status line background
	bg_float = "#0f0a1a",   -- Floating window background

	-- Foreground colors
	fg = "#e8d4ff",    -- Main text (bright white with slight purple tint)
	fg_alt = "#b89dd9", -- Secondary text (muted purple-white)
	fg_dark = "#6b5b7a", -- Darker text (comments, line numbers)
	fg_light = "#f4e6ff", -- Light text (keywords, important elements)

	-- Primary syntax colors - Vibrant neon palette
	pink = "#ff2e97", -- Hot pink (primary accent, keywords)
	magenta = "#d946ef", -- Vivid magenta (statements, control flow)
	purple = "#a855f7", -- Electric purple (functions, types)
	cyan = "#22d3ee", -- Neon cyan (strings, constants)
	blue = "#3b82f6", -- Bright blue (identifiers)

	-- Secondary neon colors
	hot_pink = "#ff1493",   -- Deep hot pink (errors, important)
	neon_pink = "#ff69b4",  -- Lighter neon pink (special elements)
	electric_blue = "#00d9ff", -- Electric blue (numbers, constants)
	lavender = "#b794f6",   -- Soft lavender (parameters, subtle elements)
	rose = "#fb7185",       -- Rose pink (characters, special chars)

	-- UI element colors
	gray = "#4a4458",    -- Borders, separators
	gray_light = "#5c5266", -- Light borders, inactive elements
	gray_dark = "#2a2435", -- Dark borders, disabled elements

	-- Accent colors
	green = "#10b981", -- Success states
	yellow = "#fbbf24", -- Warnings
	orange = "#f97316", -- Special warnings
	red = "#ef4444", -- Errors, deletions

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
	vim.g.colors_name = "neon_dreams"

	-- Editor highlights
	highlight("Normal", { fg = colors.fg, bg = colors.bg })
	highlight("NormalFloat", { fg = colors.fg, bg = colors.bg_float })
	highlight("NormalNC", { fg = colors.fg_alt, bg = colors.bg })

	-- Cursor and selection
	highlight("Cursor", { fg = colors.bg, bg = colors.pink })
	highlight("CursorLine", { bg = colors.bg_light })
	highlight("CursorColumn", { bg = colors.bg_lighter })
	highlight("ColorColumn", { bg = colors.bg_lighter })
	highlight("Visual", { bg = colors.bg_lighter, fg = colors.neon_pink })
	highlight("VisualNOS", { bg = colors.bg_lighter })

	-- Line numbers
	highlight("LineNr", { fg = colors.gray })
	highlight("CursorLineNr", { fg = colors.pink, style = "bold" })
	highlight("SignColumn", { fg = colors.gray, bg = colors.bg })

	-- Search and matching
	highlight("Search", { fg = colors.bg, bg = colors.cyan })
	highlight("IncSearch", { fg = colors.bg, bg = colors.pink })
	highlight("MatchParen", { fg = colors.pink, style = "bold,underline" })

	-- Splits and windows
	highlight("VertSplit", { fg = colors.pink, bg = colors.bg })
	highlight("WinSeparator", { fg = colors.pink, bg = colors.bg })
	highlight("StatusLine", { fg = colors.fg_light, bg = colors.bg_light })
	highlight("StatusLineNC", { fg = colors.fg_dark, bg = colors.bg_statusline })

	-- Tabs
	highlight("TabLine", { fg = colors.fg_dark, bg = colors.bg_light })
	highlight("TabLineSel", { fg = colors.pink, bg = colors.bg_lighter, style = "bold" })
	highlight("TabLineFill", { bg = colors.bg_light })

	-- Popup menu
	highlight("Pmenu", { fg = colors.fg, bg = colors.bg_alt })
	highlight("PmenuSel", { fg = colors.pink, bg = colors.bg_lighter, style = "bold" })
	highlight("PmenuSbar", { bg = colors.gray_dark })
	highlight("PmenuThumb", { bg = colors.pink })

	-- Messages and command line
	highlight("ModeMsg", { fg = colors.cyan, style = "bold" })
	highlight("MoreMsg", { fg = colors.green, style = "bold" })
	highlight("ErrorMsg", { fg = colors.hot_pink, style = "bold" })
	highlight("WarningMsg", { fg = colors.yellow, style = "bold" })

	-- Folds
	highlight("Folded", { fg = colors.fg_dark, bg = colors.bg_light })
	highlight("FoldColumn", { fg = colors.gray, bg = colors.bg })

	-- Diffs
	highlight("DiffAdd", { fg = colors.green, bg = colors.bg })
	highlight("DiffChange", { fg = colors.cyan, bg = colors.bg })
	highlight("DiffDelete", { fg = colors.hot_pink, bg = colors.bg })
	highlight("DiffText", { fg = colors.yellow, bg = colors.gray_dark })

	-- Spelling
	highlight("SpellBad", { sp = colors.hot_pink, style = "undercurl" })
	highlight("SpellCap", { sp = colors.cyan, style = "undercurl" })
	highlight("SpellLocal", { sp = colors.purple, style = "undercurl" })
	highlight("SpellRare", { sp = colors.magenta, style = "undercurl" })

	-- Miscellaneous
	highlight("Directory", { fg = colors.cyan })
	highlight("Title", { fg = colors.pink, style = "bold" })
	highlight("Question", { fg = colors.cyan })
	highlight("NonText", { fg = colors.gray })
	highlight("SpecialKey", { fg = colors.gray_light })
	highlight("Whitespace", { fg = colors.gray_dark })

	-- Syntax highlighting
	highlight("Comment", { fg = colors.gray, style = "italic" })
	highlight("Constant", { fg = colors.electric_blue })
	highlight("String", { fg = colors.cyan })
	highlight("Character", { fg = colors.rose })
	highlight("Number", { fg = colors.electric_blue })
	highlight("Boolean", { fg = colors.magenta })
	highlight("Float", { fg = colors.electric_blue })

	highlight("Identifier", { fg = colors.lavender })
	highlight("Function", { fg = colors.purple, style = "bold" })

	highlight("Statement", { fg = colors.pink, style = "bold" })
	highlight("Conditional", { fg = colors.pink })
	highlight("Repeat", { fg = colors.pink })
	highlight("Label", { fg = colors.magenta })
	highlight("Operator", { fg = colors.neon_pink })
	highlight("Keyword", { fg = colors.pink })
	highlight("Exception", { fg = colors.hot_pink })

	highlight("PreProc", { fg = colors.magenta })
	highlight("Include", { fg = colors.pink })
	highlight("Define", { fg = colors.magenta })
	highlight("Macro", { fg = colors.hot_pink })
	highlight("PreCondit", { fg = colors.magenta })

	highlight("Type", { fg = colors.purple })
	highlight("StorageClass", { fg = colors.purple })
	highlight("Structure", { fg = colors.purple })
	highlight("Typedef", { fg = colors.purple })

	highlight("Special", { fg = colors.neon_pink })
	highlight("SpecialChar", { fg = colors.rose })
	highlight("Tag", { fg = colors.pink })
	highlight("Delimiter", { fg = colors.fg_alt })
	highlight("SpecialComment", { fg = colors.lavender, style = "italic" })
	highlight("Debug", { fg = colors.hot_pink })

	highlight("Underlined", { style = "underline" })
	highlight("Ignore", { fg = colors.gray })
	highlight("Error", { fg = colors.hot_pink, style = "bold" })
	highlight("Todo", { fg = colors.yellow, bg = colors.bg, style = "bold" })

	-- Treesitter highlights
	highlight("@comment", { fg = colors.gray, style = "italic" })
	highlight("@comment.documentation", { fg = colors.lavender, style = "italic" })

	highlight("@keyword", { fg = colors.pink })
	highlight("@keyword.function", { fg = colors.pink })
	highlight("@keyword.operator", { fg = colors.neon_pink })
	highlight("@keyword.return", { fg = colors.pink })
	highlight("@keyword.conditional", { fg = colors.pink })
	highlight("@keyword.repeat", { fg = colors.pink })
	highlight("@keyword.import", { fg = colors.magenta })

	highlight("@function", { fg = colors.purple })
	highlight("@function.builtin", { fg = colors.purple, style = "bold" })
	highlight("@function.call", { fg = colors.purple })
	highlight("@function.macro", { fg = colors.hot_pink })
	highlight("@method", { fg = colors.purple })
	highlight("@method.call", { fg = colors.purple })

	highlight("@variable", { fg = colors.fg })
	highlight("@variable.builtin", { fg = colors.lavender })
	highlight("@variable.parameter", { fg = colors.lavender })
	highlight("@variable.member", { fg = colors.fg_alt })

	highlight("@string", { fg = colors.cyan })
	highlight("@string.documentation", { fg = colors.cyan, style = "italic" })
	highlight("@string.regex", { fg = colors.electric_blue })
	highlight("@string.escape", { fg = colors.neon_pink })

	highlight("@character", { fg = colors.rose })
	highlight("@character.special", { fg = colors.rose })

	highlight("@number", { fg = colors.electric_blue })
	highlight("@number.float", { fg = colors.electric_blue })
	highlight("@boolean", { fg = colors.magenta })

	highlight("@type", { fg = colors.purple })
	highlight("@type.builtin", { fg = colors.purple })
	highlight("@type.definition", { fg = colors.purple })

	highlight("@constant", { fg = colors.electric_blue })
	highlight("@constant.builtin", { fg = colors.electric_blue })
	highlight("@constant.macro", { fg = colors.electric_blue })

	highlight("@constructor", { fg = colors.purple })
	highlight("@namespace", { fg = colors.magenta })
	highlight("@module", { fg = colors.magenta })

	highlight("@operator", { fg = colors.neon_pink })
	highlight("@punctuation.delimiter", { fg = colors.fg_alt })
	highlight("@punctuation.bracket", { fg = colors.neon_pink })
	highlight("@punctuation.special", { fg = colors.pink })

	highlight("@tag", { fg = colors.pink })
	highlight("@tag.attribute", { fg = colors.purple })
	highlight("@tag.delimiter", { fg = colors.neon_pink })

	highlight("@property", { fg = colors.lavender })
	highlight("@field", { fg = colors.lavender })

	highlight("@label", { fg = colors.magenta })

	-- LSP highlights
	highlight("DiagnosticError", { fg = colors.hot_pink })
	highlight("DiagnosticWarn", { fg = colors.yellow })
	highlight("DiagnosticInfo", { fg = colors.cyan })
	highlight("DiagnosticHint", { fg = colors.lavender })

	highlight("DiagnosticUnderlineError", { sp = colors.hot_pink, style = "undercurl" })
	highlight("DiagnosticUnderlineWarn", { sp = colors.yellow, style = "undercurl" })
	highlight("DiagnosticUnderlineInfo", { sp = colors.cyan, style = "undercurl" })
	highlight("DiagnosticUnderlineHint", { sp = colors.lavender, style = "undercurl" })

	highlight("LspReferenceText", { bg = colors.bg_light })
	highlight("LspReferenceRead", { bg = colors.bg_light })
	highlight("LspReferenceWrite", { bg = colors.bg_light, style = "bold" })

	highlight("LspSignatureActiveParameter", { fg = colors.pink, style = "bold" })

	-- Git signs
	highlight("GitSignsAdd", { fg = colors.green })
	highlight("GitSignsChange", { fg = colors.cyan })
	highlight("GitSignsDelete", { fg = colors.hot_pink })

	-- Telescope
	highlight("TelescopeNormal", { fg = colors.fg, bg = colors.bg_float })
	highlight("TelescopeBorder", { fg = colors.pink, bg = colors.bg_float })
	highlight("TelescopePromptBorder", { fg = colors.pink, bg = colors.bg_float })
	highlight("TelescopeResultsBorder", { fg = colors.magenta, bg = colors.bg_float })
	highlight("TelescopePreviewBorder", { fg = colors.purple, bg = colors.bg_float })

	highlight("TelescopeSelection", { fg = colors.pink, bg = colors.bg_light, style = "bold" })
	highlight("TelescopeSelectionCaret", { fg = colors.pink, bg = colors.bg_light })
	highlight("TelescopeMultiSelection", { fg = colors.magenta, bg = colors.bg_light })

	highlight("TelescopeMatching", { fg = colors.cyan, style = "bold" })
	highlight("TelescopePromptPrefix", { fg = colors.pink })

	-- NvimTree
	highlight("NvimTreeNormal", { fg = colors.fg, bg = colors.bg_alt })
	highlight("NvimTreeWinSeparator", { fg = colors.pink, bg = colors.bg_alt })
	highlight("NvimTreeRootFolder", { fg = colors.pink, style = "bold" })
	highlight("NvimTreeFolderName", { fg = colors.purple })
	highlight("NvimTreeFolderIcon", { fg = colors.magenta })
	highlight("NvimTreeOpenedFolderName", { fg = colors.pink })
	highlight("NvimTreeIndentMarker", { fg = colors.gray })
	highlight("NvimTreeGitDirty", { fg = colors.yellow })
	highlight("NvimTreeGitNew", { fg = colors.green })
	highlight("NvimTreeGitDeleted", { fg = colors.hot_pink })
	highlight("NvimTreeSpecialFile", { fg = colors.neon_pink })
	highlight("NvimTreeImageFile", { fg = colors.rose })
	highlight("NvimTreeExecFile", { fg = colors.cyan })

	-- IndentBlankline
	highlight("IndentBlanklineChar", { fg = colors.gray_dark })
	highlight("IndentBlanklineContextChar", { fg = colors.pink })
	highlight("IndentBlanklineContextStart", { sp = colors.pink, style = "underline" })

	-- Which-key
	highlight("WhichKey", { fg = colors.pink })
	highlight("WhichKeyGroup", { fg = colors.magenta })
	highlight("WhichKeyDesc", { fg = colors.fg })
	highlight("WhichKeySeperator", { fg = colors.gray })
	highlight("WhichKeyFloat", { bg = colors.bg_float })
	highlight("WhichKeyBorder", { fg = colors.pink })

	-- BufferLine
	highlight("BufferLineIndicatorSelected", { fg = colors.pink })
	highlight("BufferLineFill", { bg = colors.bg_statusline })

	-- Notify
	highlight("NotifyBackground", { bg = colors.bg_float })
	highlight("NotifyERRORBorder", { fg = colors.hot_pink })
	highlight("NotifyWARNBorder", { fg = colors.yellow })
	highlight("NotifyINFOBorder", { fg = colors.cyan })
	highlight("NotifyDEBUGBorder", { fg = colors.gray })
	highlight("NotifyTRACEBorder", { fg = colors.purple })

	-- CMP (completion)
	highlight("CmpItemAbbrDeprecated", { fg = colors.gray, style = "strikethrough" })
	highlight("CmpItemAbbrMatch", { fg = colors.pink, style = "bold" })
	highlight("CmpItemAbbrMatchFuzzy", { fg = colors.pink })
	highlight("CmpItemKindVariable", { fg = colors.lavender })
	highlight("CmpItemKindInterface", { fg = colors.purple })
	highlight("CmpItemKindText", { fg = colors.fg })
	highlight("CmpItemKindFunction", { fg = colors.purple })
	highlight("CmpItemKindMethod", { fg = colors.purple })
	highlight("CmpItemKindKeyword", { fg = colors.pink })
	highlight("CmpItemKindProperty", { fg = colors.lavender })
	highlight("CmpItemKindUnit", { fg = colors.cyan })

	-- Markdown highlights
	highlight("markdownCode", { fg = colors.cyan, bg = colors.bg_lighter })
	highlight("markdownCodeBlock", { fg = colors.fg_alt, bg = colors.bg_lighter })
	highlight("markdownCodeDelimiter", { fg = colors.pink, bg = colors.bg_lighter })
	highlight("markdownH1", { fg = colors.pink, style = "bold" })
	highlight("markdownH2", { fg = colors.magenta, style = "bold" })
	highlight("markdownH3", { fg = colors.purple, style = "bold" })
	highlight("markdownH4", { fg = colors.purple })
	highlight("markdownH5", { fg = colors.lavender })
	highlight("markdownH6", { fg = colors.lavender })
	highlight("markdownHeadingDelimiter", { fg = colors.pink, style = "bold" })
	highlight("markdownHeadingRule", { fg = colors.pink, style = "bold" })
	highlight("markdownBold", { fg = colors.fg_light, style = "bold" })
	highlight("markdownItalic", { fg = colors.fg_light, style = "italic" })
	highlight("markdownBoldItalic", { fg = colors.pink, style = "bold,italic" })
	highlight("markdownUrl", { fg = colors.cyan, style = "underline" })
	highlight("markdownLink", { fg = colors.purple })
	highlight("markdownLinkText", { fg = colors.magenta })
	highlight("markdownLinkDelimiter", { fg = colors.gray })
	highlight("markdownLinkTextDelimiter", { fg = colors.gray })
	highlight("markdownListMarker", { fg = colors.pink })
	highlight("markdownOrderedListMarker", { fg = colors.pink })
	highlight("markdownRule", { fg = colors.pink })
	highlight("markdownBlockquote", { fg = colors.lavender, style = "italic" })

	-- Treesitter markdown highlights
	highlight("@markup.heading.1.markdown", { fg = colors.pink, style = "bold" })
	highlight("@markup.heading.2.markdown", { fg = colors.magenta, style = "bold" })
	highlight("@markup.heading.3.markdown", { fg = colors.purple, style = "bold" })
	highlight("@markup.heading.4.markdown", { fg = colors.purple })
	highlight("@markup.heading.5.markdown", { fg = colors.lavender })
	highlight("@markup.heading.6.markdown", { fg = colors.lavender })
	highlight("@markup.strong.markdown_inline", { fg = colors.pink, style = "bold" })
	highlight("@markup.italic.markdown_inline", { fg = colors.fg_light, style = "italic" })
	highlight("@markup.raw.markdown_inline", { fg = colors.cyan, bg = colors.bg_lighter })
	highlight("@markup.raw.block.markdown", { fg = colors.fg_alt, bg = colors.bg_lighter })
	highlight("@markup.link.label.markdown_inline", { fg = colors.magenta })
	highlight("@markup.link.url.markdown_inline", { fg = colors.cyan, style = "underline" })
	highlight("@markup.list.markdown", { fg = colors.pink })
	highlight("@markup.quote.markdown", { fg = colors.lavender, style = "italic" })

	-- HTML highlights
	highlight("htmlH1", { fg = colors.pink, style = "bold" })
	highlight("htmlH2", { fg = colors.magenta, style = "bold" })
	highlight("htmlH3", { fg = colors.purple, style = "bold" })
	highlight("htmlH4", { fg = colors.purple })
	highlight("htmlH5", { fg = colors.lavender })
	highlight("htmlH6", { fg = colors.lavender })

	-- Markdown code block delimiters
	highlight("@markup.raw.delimiter.markdown", { fg = colors.pink, bg = colors.bg_lighter })
	highlight("@markup.raw.language.markdown", { fg = colors.magenta, bg = colors.bg_lighter })

	-- vim-markdown plugin
	highlight("mkdCodeDelimiter", { fg = colors.pink, bg = colors.bg_lighter })
	highlight("mkdCodeStart", { fg = colors.pink, bg = colors.bg_lighter })
	highlight("mkdCodeEnd", { fg = colors.pink, bg = colors.bg_lighter })
	highlight("mkdCode", { fg = colors.cyan, bg = colors.bg_lighter })
end

return M
