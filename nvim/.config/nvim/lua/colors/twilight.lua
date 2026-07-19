-- Custom colorscheme converted to Lua
-- Original vim colorscheme from github.com/CosecSecCot/cosec-twilight.nvim

local M = {}

-- Color palette from original vim colorscheme
local colors = {
	-- Core backgrounds
	bg = "#202020",
	bg_alt = "#262626",
	bg_light = "#303030",
	bg_statusline = "#34383C",
	bg_float = "#202020",

	-- Foreground colors
	fg = "#FEFEFE",
	fg_alt = "#918988",
	fg_dark = "#474A4D",

	-- Syntax colors
	comment = "#6f7b68",
	constant = "#cccccc",
	string = "#A2A970",
	character = "#C1C88D",
	number = "#6f7b68",
	boolean = "#6f7b68",
	float = "#6f7b68",

	function_color = "#AA9AAC",
	identifier = "#8B9698",
	operator = "#DEBF7C",
	preproc = "#8B9698",
	special = "#cccccc",
	special_char = "#C1C88D",
	statement = "#cccccc",
	structure = "#AA9AAC",
	type = "#E3D896",
	todo = "#8B9698",

	-- UI colors
	line_nr = "#d6d2c8",
	line_nr_other = "#888888",
	line_nr_bg = "#222222",
	directory = "#C1C88D",
	match_paren = "#FFFEDB",
	non_text = "#303030",
	special_key = "#676767",
	question = "#9b8d7f",

	-- Selection and search
	visual = "#454545",
	search = "#5F5958",
	substitute_fg = "#1A1A1A",
	substitute_bg = "#C1C88D",

	-- Diff colors
	diff_add_fg = "#FFFEDB",
	diff_add_bg = "#2B3328",
	diff_change_fg = "#FFFEDB",
	diff_change_bg = "#262636",
	diff_delete_fg = "#C34143",
	diff_delete_bg = "#42242B",
	diff_text_fg = "#FFFEDB",
	diff_text_bg = "#49443C",

	-- Status and message colors
	error = "#C34143",
	warning = "#FFFEDB",

	-- Menu colors
	pmenu_fg = "#918988",
	pmenu_bg = "#303030",
	pmenu_sel_fg = "#BFBBBA",
	pmenu_sbar_bg = "#262626",

	-- Tab colors
	tab_fg = "#A09998",
	tab_bg = "#212121",
	tab_sel_bg = "#40474F",

	-- Separator colors
	vert_split = "#303030",
	win_separator_bg = "#111111",
	win_separator_fg = "#888888",

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
	if opts.cterm then
		cmd = cmd .. " cterm=" .. opts.cterm
	end
	if opts.term then
		cmd = cmd .. " term=" .. opts.term
	end
	vim.cmd(cmd)
end

function M.setup()
	-- Reset highlights
	vim.cmd("highlight clear")
	if vim.fn.exists("syntax_on") then
		vim.cmd("syntax reset")
	end

	vim.o.background = "dark"
	vim.o.termguicolors = true
	vim.g.colors_name = "custom"

	-- Editor highlights
	highlight("Normal", { fg = colors.fg, bg = colors.bg })
	highlight("NormalFloat", { fg = colors.fg, bg = colors.bg_float })
	highlight("Conceal", { bg = colors.bg_alt })

	-- Comments
	highlight("Comment", { fg = colors.comment })
	highlight("TSComment", { fg = colors.comment })

	-- Constants
	highlight("Constant", { fg = colors.constant })
	highlight("String", { fg = colors.string })
	highlight("Character", { fg = colors.character })
	highlight("Number", { fg = colors.number })
	highlight("Boolean", { fg = colors.boolean })
	highlight("Float", { fg = colors.float })

	-- Cursor and visual
	highlight("CursorLine", { bg = colors.none })
	highlight("CursorColumn", { bg = colors.none })
	highlight("Visual", { bg = colors.visual })

	-- Diff
	highlight("DiffAdd", { fg = colors.diff_add_fg, bg = colors.diff_add_bg })
	highlight("DiffChange", { fg = colors.diff_change_fg, bg = colors.diff_change_bg })
	highlight("DiffDelete", { fg = colors.diff_delete_fg, bg = colors.diff_delete_bg })
	highlight("DiffText", { fg = colors.diff_text_fg, bg = colors.diff_text_bg })

	-- Directory
	highlight("Directory", { fg = colors.directory })

	-- Errors and warnings
	highlight("Error", { fg = colors.error, style = "undercurl" })
	highlight("ErrorMsg", { fg = colors.warning })
	highlight("WarningMsg", { fg = colors.warning })

	-- Functions and identifiers
	highlight("Function", { fg = colors.function_color })
	highlight("Identifier", { fg = colors.identifier })

	-- Line numbers
	highlight("LineNr", { fg = colors.line_nr })
	highlight("LineNrAbove", { fg = colors.line_nr_other, bg = colors.line_nr_bg })
	highlight("LineNrBelow", { fg = colors.line_nr_other, bg = colors.line_nr_bg })
	highlight("SignColumn", { bg = colors.none })
	highlight("FoldColumn", { bg = colors.none })

	-- Matching
	highlight("MatchParen", { fg = colors.match_paren })

	-- Non-text
	highlight("NonText", { fg = colors.non_text })
	highlight("SpecialKey", { fg = colors.special_key })

	-- Operators
	highlight("Operator", { fg = colors.operator })

	-- Popup menu
	highlight("Pmenu", { fg = colors.pmenu_fg, bg = colors.pmenu_bg })
	highlight("PmenuSbar", { fg = colors.pmenu_fg, bg = colors.pmenu_sbar_bg })
	highlight("PmenuSel", { fg = colors.pmenu_sel_fg, bg = colors.pmenu_bg })
	highlight("PmenuThumb", { fg = colors.pmenu_fg, bg = colors.pmenu_sbar_bg, style = "reverse" })

	-- Preprocessor
	highlight("PreProc", { fg = colors.preproc })

	-- Questions
	highlight("Question", { fg = colors.question })

	-- QuickFix
	highlight("QuickFixLine", { bg = colors.bg_light })

	-- Search
	highlight("Search", { bg = colors.search })

	-- Special
	highlight("Special", { fg = colors.special })
	highlight("SpecialChar", { fg = colors.special_char })

	-- Statements
	highlight("Statement", { fg = colors.statement })

	-- Status line
	highlight("StatusLine", { fg = colors.warning, bg = colors.bg_statusline })

	-- Structure and types
	highlight("Structure", { fg = colors.structure })
	highlight("Type", { fg = colors.type })

	-- Substitute
	highlight("Substitute", { fg = colors.substitute_fg, bg = colors.substitute_bg })

	-- Tabs
	highlight("TabLine", { fg = colors.tab_fg, bg = colors.tab_bg })
	highlight("TabLineFill", { fg = colors.tab_fg, bg = colors.tab_bg })
	highlight("TabLineSel", { fg = colors.tab_fg, bg = colors.tab_sel_bg })

	-- Title and Todo
	highlight("Title", { fg = colors.warning, style = "none", term = "none", cterm = "none" })
	highlight("Todo", { fg = colors.todo })

	-- Underline
	highlight("Underlined", { style = "undercurl" })

	-- Vertical split
	highlight("VertSplit", { fg = colors.vert_split })
	highlight("WinSeparator", { bg = colors.win_separator_bg, fg = colors.win_separator_fg })

	-- Folding (no specific settings in original)
	highlight("Folded", { bg = colors.none })

	-- Markdown
	highlight("@markup.link.label.markdown_inline", { cterm = "NONE" })
end

return M
