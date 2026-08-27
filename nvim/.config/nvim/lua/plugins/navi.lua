return {
	"navi",
	virtual = true,
	lazy = false,
	priority = 1000,
	config = function()
		vim.cmd.colorscheme("navi")

		local hl = vim.api.nvim_set_hl
		local c = {
			bg = "#02050c",
			surface = "#10192a",
			elevated = "#152036",
			border = "#35506f",
			fg = "#edf4ff",
			fg_alt = "#8ea2bf",
			accent = "#7ec4ff",
			accent_text = "#eaf5ff",
			selection_bg = "#204064",
			selection_border = "#95d3ff",
			orange = "#ffb86c",
			green = "#57c957",
			red = "#e86060",
			chrome_alt = "#0b1220",
			grid_selection_band = "#3c2c0e",
			grid_yank_band = "#143c16",
			grid_cut_band = "#3e1416",
		}

		-- Base
		hl(0, "Normal", { fg = c.fg, bg = c.bg })
		hl(0, "NormalFloat", { fg = c.fg, bg = c.surface })
		hl(0, "Cursor", { fg = c.bg, bg = c.accent_text })
		hl(0, "lCursor", { fg = c.bg, bg = c.accent_text })
		hl(0, "CursorIM", { fg = c.bg, bg = c.accent_text })
		hl(0, "SignColumn", { bg = c.bg })

		-- Syntax
		hl(0, "Comment", { fg = c.fg_alt, italic = true })
		hl(0, "SpecialComment", { fg = c.fg_alt, italic = true })
		hl(0, "Constant", { fg = c.orange })
		hl(0, "String", { fg = c.green })
		hl(0, "Character", { fg = c.green })
		hl(0, "Number", { fg = c.orange })
		hl(0, "Boolean", { fg = c.orange })
		hl(0, "Float", { fg = c.orange })
		hl(0, "Identifier", { fg = c.accent_text })
		hl(0, "Function", { fg = c.accent })
		hl(0, "Statement", { fg = c.accent, bold = true })
		hl(0, "Conditional", { fg = c.accent })
		hl(0, "Repeat", { fg = c.accent })
		hl(0, "Label", { fg = c.accent })
		hl(0, "Operator", { fg = c.fg })
		hl(0, "Keyword", { fg = c.accent })
		hl(0, "Exception", { fg = c.red })
		hl(0, "PreProc", { fg = c.selection_border })
		hl(0, "Include", { fg = c.accent })
		hl(0, "Define", { fg = c.accent })
		hl(0, "Macro", { fg = c.selection_border })
		hl(0, "Type", { fg = c.selection_border })
		hl(0, "StorageClass", { fg = c.accent })
		hl(0, "Structure", { fg = c.accent })
		hl(0, "Typedef", { fg = c.selection_border })
		hl(0, "Special", { fg = c.orange })
		hl(0, "SpecialChar", { fg = c.orange })
		hl(0, "Tag", { fg = c.selection_border })
		hl(0, "Delimiter", { fg = c.fg_alt })
		hl(0, "Debug", { fg = c.orange })
		hl(0, "Underlined", { fg = c.accent, underline = true })
		hl(0, "Ignore", { fg = c.fg_alt })
		hl(0, "Error", { fg = c.red, bold = true })
		hl(0, "Todo", { fg = c.bg, bg = c.orange, bold = true })

		-- Editor UI
		hl(0, "LineNr", { fg = c.fg_alt })
		hl(0, "CursorLineNr", { fg = c.accent_text, bold = true })
		hl(0, "CursorLine", { bg = c.surface })
		hl(0, "CursorColumn", { bg = c.surface })
		hl(0, "ColorColumn", { bg = c.elevated })
		hl(0, "Visual", { bg = c.selection_bg })
		hl(0, "VisualNOS", { bg = c.selection_bg })
		hl(0, "Search", { fg = c.bg, bg = c.orange })
		hl(0, "IncSearch", { fg = c.bg, bg = c.selection_border })
		hl(0, "CurSearch", { fg = c.bg, bg = c.selection_border })
		hl(0, "MatchParen", { fg = c.selection_border, bold = true })
		hl(0, "StatusLine", { fg = c.accent_text, bg = c.elevated })
		hl(0, "StatusLineNC", { fg = c.fg_alt, bg = c.surface })
		hl(0, "WinSeparator", { fg = c.border, bg = c.bg })
		hl(0, "VertSplit", { fg = c.border, bg = c.bg })
		hl(0, "Pmenu", { fg = c.fg, bg = c.surface })
		hl(0, "PmenuSel", { fg = c.accent_text, bg = c.selection_bg })
		hl(0, "PmenuSbar", { bg = c.elevated })
		hl(0, "PmenuThumb", { bg = c.border })
		hl(0, "TabLine", { fg = c.fg_alt, bg = c.chrome_alt })
		hl(0, "TabLineSel", { fg = c.accent_text, bg = c.elevated })
		hl(0, "TabLineFill", { bg = c.chrome_alt })
		hl(0, "Title", { fg = c.accent, bold = true })
		hl(0, "Directory", { fg = c.accent })
		hl(0, "Question", { fg = c.green })
		hl(0, "MoreMsg", { fg = c.green })
		hl(0, "WarningMsg", { fg = c.orange })
		hl(0, "ErrorMsg", { fg = c.red, bold = true })
		hl(0, "ModeMsg", { fg = c.fg })
		hl(0, "Folded", { fg = c.fg_alt, bg = c.chrome_alt })
		hl(0, "FoldColumn", { fg = c.fg_alt, bg = c.bg })

		-- Diff
		hl(0, "DiffAdd", { fg = c.green, bg = c.grid_yank_band })
		hl(0, "DiffChange", { fg = c.orange, bg = c.grid_selection_band })
		hl(0, "DiffDelete", { fg = c.red, bg = c.grid_cut_band })
		hl(0, "DiffText", { fg = c.accent_text, bg = c.selection_bg })

		-- Spelling
		hl(0, "SpellBad", { fg = c.red, undercurl = true })
		hl(0, "SpellCap", { fg = c.orange, undercurl = true })
		hl(0, "SpellRare", { fg = c.selection_border, undercurl = true })
		hl(0, "SpellLocal", { fg = c.accent, undercurl = true })

		-- LSP diagnostics
		hl(0, "DiagnosticError", { fg = c.red })
		hl(0, "DiagnosticWarn", { fg = c.orange })
		hl(0, "DiagnosticInfo", { fg = c.accent })
		hl(0, "DiagnosticHint", { fg = c.green })
		hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = c.red })
		hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = c.orange })
		hl(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = c.accent })
		hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = c.green })
		hl(0, "DiagnosticVirtualTextError", { fg = c.red })
		hl(0, "DiagnosticVirtualTextWarn", { fg = c.orange })
		hl(0, "DiagnosticVirtualTextInfo", { fg = c.accent })
		hl(0, "DiagnosticVirtualTextHint", { fg = c.green })
		hl(0, "DiagnosticSignError", { fg = c.red })
		hl(0, "DiagnosticSignWarn", { fg = c.orange })
		hl(0, "DiagnosticSignInfo", { fg = c.accent })
		hl(0, "DiagnosticSignHint", { fg = c.green })
	end,
}