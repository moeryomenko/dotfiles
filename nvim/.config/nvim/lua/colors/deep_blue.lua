-- Deep Blue colorscheme for Neovim
-- Inspired by atmospheric blue tones

local M = {}

-- Color palette extracted from the image
local colors = {
	-- Main blues from the image
	bg = "#0a1428", -- Very dark blue background
	bg_alt = "#0f1a2e", -- Slightly lighter background
	bg_light = "#152135", -- Light background elements
	fg = "#4a6ba3", -- Light blue-gray foreground
	fg_alt = "#5c7db8", -- Muted foreground

	-- Accent colors derived from image tones
	blue = "#3d5a7a", -- Mid-tone blue
	light_blue = "#5c7ea3", -- Lighter blue accent
	dark_blue = "#1e2f42", -- Darker blue
	cyan = "#4a6b8a", -- Blue-cyan

	-- Complementary colors for syntax highlighting
	gray = "#4a5568", -- Neutral gray
	light_gray = "#718096", -- Light gray
	dark_gray = "#2d3748", -- Dark gray

	-- Status colors (maintaining blue theme)
	green = "#4a7c59", -- Muted green
	yellow = "#7a7c4a", -- Muted yellow
	red = "#7a4a4a", -- Muted red
	orange = "#7a5f4a", -- Muted orange
	purple = "#4a2d7a", -- Muted purple

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
	vim.g.colors_name = "deep_blue"

	-- Editor highlights
	highlight("Normal", { fg = colors.fg, bg = colors.bg })
	highlight("NormalFloat", { fg = colors.fg, bg = colors.bg_alt })
	highlight("NormalNC", { fg = colors.fg_alt, bg = colors.bg })

	-- Cursor and selection
	highlight("Cursor", { fg = colors.bg, bg = colors.light_blue })
	highlight("CursorLine", { bg = colors.bg_light })
	highlight("CursorColumn", { bg = colors.bg_light })
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
	highlight("VertSplit", { fg = colors.dark_gray, bg = colors.bg })
	highlight("WinSeparator", { fg = colors.dark_gray, bg = colors.bg })
	highlight("StatusLine", { fg = colors.fg, bg = colors.bg_light })
	highlight("StatusLineNC", { fg = colors.gray, bg = colors.dark_gray })

	-- Tabs
	highlight("TabLine", { fg = colors.gray, bg = colors.bg_light })
	highlight("TabLineSel", { fg = colors.fg, bg = colors.blue })
	highlight("TabLineFill", { bg = colors.bg_light })

	-- Popup menu
	highlight("Pmenu", { fg = colors.fg, bg = colors.bg_alt })
	highlight("PmenuSel", { fg = colors.bg, bg = colors.light_blue })
	highlight("PmenuSbar", { bg = colors.dark_gray })
	highlight("PmenuThumb", { bg = colors.gray })

	-- Messages and command line
	highlight("ModeMsg", { fg = colors.light_blue, style = "bold" })
	highlight("MoreMsg", { fg = colors.green, style = "bold" })
	highlight("ErrorMsg", { fg = colors.red, style = "bold" })
	highlight("WarningMsg", { fg = colors.yellow, style = "bold" })

	-- Folds
	highlight("Folded", { fg = colors.gray, bg = colors.bg_light })
	highlight("FoldColumn", { fg = colors.gray, bg = colors.bg })

	-- Diffs
	highlight("DiffAdd", { fg = colors.green, bg = colors.bg })
	highlight("DiffChange", { fg = colors.yellow, bg = colors.bg })
	highlight("DiffDelete", { fg = colors.red, bg = colors.bg })
	highlight("DiffText", { fg = colors.yellow, bg = colors.dark_gray })

	-- Spelling
	highlight("SpellBad", { sp = colors.red, style = "undercurl" })
	highlight("SpellCap", { sp = colors.blue, style = "undercurl" })
	highlight("SpellLocal", { sp = colors.cyan, style = "undercurl" })
	highlight("SpellRare", { sp = colors.purple, style = "undercurl" })

	-- Syntax highlighting
	highlight("Comment", { fg = colors.gray, style = "italic" })
	highlight("Constant", { fg = colors.cyan })
	highlight("String", { fg = colors.green })
	highlight("Character", { fg = colors.green })
	highlight("Number", { fg = colors.orange })
	highlight("Boolean", { fg = colors.orange })
	highlight("Float", { fg = colors.orange })

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

	highlight("Special", { fg = colors.red })
	highlight("SpecialChar", { fg = colors.red })
	highlight("Tag", { fg = colors.red })
	highlight("Delimiter", { fg = colors.fg_alt })
	highlight("SpecialComment", { fg = colors.gray })
	highlight("Debug", { fg = colors.red })

	highlight("Underlined", { style = "underline" })
	highlight("Ignore", { fg = colors.gray })
	highlight("Error", { fg = colors.red, style = "bold" })
	highlight("Todo", { fg = colors.yellow, bg = colors.bg, style = "bold" })

	-- Treesitter highlights (if available)
	highlight("@comment", { fg = colors.gray, style = "italic" })
	highlight("@keyword", { fg = colors.purple })
	highlight("@keyword.function", { fg = colors.purple })
	highlight("@keyword.return", { fg = colors.purple })
	highlight("@function", { fg = colors.blue })
	highlight("@function.builtin", { fg = colors.blue })
	highlight("@variable", { fg = colors.fg })
	highlight("@variable.builtin", { fg = colors.light_blue })
	highlight("@string", { fg = colors.green })
	highlight("@number", { fg = colors.orange })
	highlight("@boolean", { fg = colors.orange })
	highlight("@type", { fg = colors.light_blue })
	highlight("@type.builtin", { fg = colors.light_blue })
	highlight("@constant", { fg = colors.cyan })
	highlight("@constant.builtin", { fg = colors.cyan })
	highlight("@operator", { fg = colors.fg })
	highlight("@punctuation.delimiter", { fg = colors.fg_alt })
	highlight("@punctuation.bracket", { fg = colors.fg_alt })

	-- LSP highlights
	highlight("DiagnosticError", { fg = colors.red })
	highlight("DiagnosticWarn", { fg = colors.yellow })
	highlight("DiagnosticInfo", { fg = colors.blue })
	highlight("DiagnosticHint", { fg = colors.cyan })
	highlight("DiagnosticUnderlineError", { sp = colors.red, style = "undercurl" })
	highlight("DiagnosticUnderlineWarn", { sp = colors.yellow, style = "undercurl" })
	highlight("DiagnosticUnderlineInfo", { sp = colors.blue, style = "undercurl" })
	highlight("DiagnosticUnderlineHint", { sp = colors.cyan, style = "undercurl" })

	-- Git signs (if using gitsigns.nvim)
	highlight("GitSignsAdd", { fg = colors.green })
	highlight("GitSignsChange", { fg = colors.yellow })
	highlight("GitSignsDelete", { fg = colors.red })

	-- Telescope (if using telescope.nvim)
	highlight("TelescopeNormal", { fg = colors.fg, bg = colors.bg_alt })
	highlight("TelescopeBorder", { fg = colors.gray, bg = colors.bg_alt })
	highlight("TelescopeSelection", { fg = colors.fg, bg = colors.bg_light })
	highlight("TelescopeMatching", { fg = colors.light_blue, style = "bold" })

	-- NvimTree (if using nvim-tree.lua)
	highlight("NvimTreeNormal", { fg = colors.fg, bg = colors.bg_alt })
	highlight("NvimTreeRootFolder", { fg = colors.light_blue, style = "bold" })
	highlight("NvimTreeFolderIcon", { fg = colors.blue })
	highlight("NvimTreeIndentMarker", { fg = colors.gray })
end

return M
