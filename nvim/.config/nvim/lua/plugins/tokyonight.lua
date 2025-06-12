return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		local styles = require("tokyonight.colors").styles

		styles.custom = {
			bg = "#08080b", -- Updated from #24283b (primary.background)
			bg_dark = "#1f2335",
			bg_dark1 = "#1b1e2d",
			bg_highlight = "#292e42",
			blue = "#7aa2f7", -- Matches normal.blue/bright.blue
			blue0 = "#3d59a1",
			blue1 = "#2ac3de",
			blue2 = "#0db9d7",
			blue5 = "#89ddff",
			blue6 = "#b4f9f8",
			blue7 = "#394b70",
			comment = "#565f89",
			cyan = "#7dcfff", -- Matches normal.cyan/bright.cyan
			dark3 = "#545c7e",
			dark5 = "#737aa2",
			fg = "#787c99", -- Updated from #c0caf5 (primary.foreground)
			fg_dark = "#a9b1d6",
			fg_gutter = "#3b4261",
			green = "#41a6b5", -- Updated from #9ece6a (normal.green/bright.green)
			green1 = "#73daca",
			green2 = "#41a6b5", -- Already matches normal.green
			magenta = "#bb9af7", -- Matches normal.magenta/bright.magenta
			magenta2 = "#ff007c",
			orange = "#ff9e64",
			purple = "#9d7cd8",
			red = "#f7768e", -- Matches normal.red/bright.red
			red1 = "#db4b4b",
			teal = "#1abc9c",
			terminal_black = "#363b54", -- Updated from #414868 (normal.black/bright.black)
			yellow = "#e0af68", -- Matches normal.yellow/bright.yellow
			git = {
				add = "#449dab",
				change = "#6183bb",
				delete = "#914c54",
			},
		}

		require("tokyonight").setup({
			on_highlights = function(hl, c)
				local prompt = "#08080b"
				hl.TelescopeNormal = {
					bg = styles.custom.bg,
					fg = styles.custom.fg,
				}
				hl.TelescopeBorder = {
					bg = styles.custom.bg,
					fg = styles.custom.bg,
				}
				hl.TelescopePromptNormal = {
					bg = prompt,
				}
				hl.TelescopePromptBorder = {
					bg = prompt,
					fg = prompt,
				}
				hl.TelescopePromptTitle = {
					bg = prompt,
					fg = prompt,
				}
				hl.TelescopePreviewTitle = {
					bg = styles.custom.bg,
					fg = styles.custom.bg,
				}
				hl.TelescopeResultsTitle = {
					bg = styles.custom.bg,
					fg = styles.custom.bg,
				}
			end,
			on_colors = function(colors)
				colors.fg = "#7dcfff"
			end,
		})

		require("tokyonight").load({ style = "custom" })
	end,
}
