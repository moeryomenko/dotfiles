return {
	"nvim-telekasten/telekasten.nvim",
	lazy = false,
	dependencies = {
		"nvim-telescope/telescope.nvim",
		"nvim-lua/plenary.nvim",
	},
	keys = {
		-- Most used functions
		{ "<leader>zf", "<cmd>lua require('telekasten').find_notes()", { desc = "Find notes" } },
		{ "<leader>zg", "<cmd>lua require('telekasten').search_notes()", { desc = "Search notes" } },
		{ "<leader>zd", "<cmd>lua require('telekasten').goto_today()", { desc = "Go to today" } },
		{ "<leader>zz", "<cmd>lua require('telekasten').follow_link()", { desc = "Follow link" } },
		{ "<leader>zn", "<cmd>lua require('telekasten').new_note()", { desc = "New note" } },
		{ "<leader>zb", "<cmd>lua require('telekasten').show_backlinks()", { desc = "Show backlinks" } },
		{ "<leader>zt", "<cmd>lua require('telekasten').show_tags()", { desc = "Show tags" } },

		-- Link manipulation
		{ "<leader>zl", "<cmd>lua require('telekasten').insert_link()<cr>", desc = "Insert link" },
		{ "<leader>zc", "<cmd>lua require('telekasten').show_calendar()<cr>", desc = "Show calendar" },
		{ "<leader>zw", "<cmd>lua require('telekasten').goto_thisweek()<cr>", desc = "Go to this week" },

		-- Quick notes
		{ "<leader>zi", "<cmd>lua require('telekasten').insert_img_link()<cr>", desc = "Insert image link" },
		{ "<leader>zp", "<cmd>lua require('telekasten').preview_img()<cr>", desc = "Preview image" },
		{ "<leader>zm", "<cmd>lua require('telekasten').browse_media()<cr>", desc = "Browse media" },

		-- Advanced features
		{ "<leader>zr", "<cmd>lua require('telekasten').rename_note()<cr>", desc = "Rename note" },
		{ "<leader>zy", "<cmd>lua require('telekasten').yank_notelink()<cr>", desc = "Yank note link" },

		-- Command palette
		{ "<leader>z<CR>", "<cmd>lua require('telekasten').panel()<cr>", desc = "Command palette" },
	},
	config = function()
		require("telekasten").setup({
			home = vim.fn.expand("~/notes"),

			-- if true, telekasten will be enabled when opening a note within the configured home
			take_over_my_home = true,

			-- auto-set telekasten filetype: if false, the telekasten filetype will not be used
			auto_set_filetype = true,

			-- dir names for special notes (absolute path or subdir name)
			dailies = vim.fn.expand("~/notes/daily"),
			weeklies = vim.fn.expand("~/notes/weekly"),
			templates = vim.fn.expand("~/notes/templates"),

			-- image (sub)dir for pasting
			image_subdir = "img",

			-- markdown file extension
			extension = ".md",

			-- Generate note filenames. One of:
			-- "title" (default) - Use title if supplied, uuid otherwise
			-- "uuid" - Use uuid
			-- "uuid-title" - Use uuid-title
			new_note_filename = "title",
			uuid_type = "%Y%m%d%H%M",
			uuid_sep = "-",

			-- following a link to a non-existing note will create it
			follow_creates_nonexisting = true,
			dailies_create_nonexisting = true,
			weeklies_create_nonexisting = true,

			-- skip telescope prompt for goto_today and goto_thisweek
			journal_auto_open = true,

			-- template for new notes (new_note, follow_link)
			-- set to `nil` or do not specify if you do not want a template
			template_new_note = vim.fn.expand("~/notes/templates/new_note.md"),

			-- template for newly created daily notes (goto_today)
			-- set to `nil` or do not specify if you do not want a template
			template_new_daily = vim.fn.expand("~/notes/templates/daily.md"),

			-- template for newly created weekly notes (goto_thisweek)
			-- set to `nil` or do not specify if you do not want a template
			template_new_weekly = vim.fn.expand("~/notes/templates/weekly.md"),

			-- image link style
			-- wiki:     ![[image name]]
			-- markdown: ![](image_subdir/xxxxx.png)
			image_link_style = "markdown",

			-- default sort option: 'filename', 'modified'
			sort = "filename",

			-- integrate with calendar-vim
			plug_into_calendar = true,
			calendar_opts = {
				-- calendar week display mode: 1 .. 'WK01', 2 .. 'WK1', 3 .. 'W01', 4 .. 'W1', 5 .. '1'
				weeknm = 4,
				-- use monday as first day of week: 1 .. true, 0 .. false
				calendar_monday = 1,
				-- calendar mark: where to put mark for marked days: 'left', 'right', 'left-fit'
				calendar_mark = "left-fit",
			},

			-- telescope actions behavior
			close_after_yanking = false,
			insert_after_inserting = true,

			-- tag notation: '#tag', ':tag:', 'yaml-bare', 'yaml-list', 'yaml-list-bare'
			tag_notation = "#tag",

			-- command palette theme: dropdown (window) or ivy (bottom panel)
			command_palette_theme = "ivy",

			-- tag list theme:
			show_tags_theme = "ivy",

			-- when linking to a note in subdir/, create a [[subdir/title]] link
			-- instead of a [[title only]] link
			subdirs_in_links = true,

			-- template_handling
			-- What to do when creating a new note via `new_note()` or `follow_link()`
			-- to a non-existing note
			-- - prefer_new_note: use `new_note` template
			-- - smart: if day or week is detected in title, use daily / weekly templates (default)
			-- - always_ask: always ask before creating a note
			template_handling = "smart",

			-- path handling:
			-- this applies to:
			-- - new_note()
			-- - new_templated_note()
			-- - follow_link() to non-existing note
			--
			-- it does NOT apply to:
			-- - goto_today()
			-- - goto_thisweek()
			--
			-- Valid options:
			-- - smart: put daily-looking notes in daily, weekly-looking ones in weekly, all other ones in home, except for notes/with/subdirs/in/title.
			-- - prefer_home: put all notes in home except for notes/with/subdirs/in/title.
			-- - same_as_current: put all new notes in the same dir as the current note.
			new_note_location = "smart",

			-- should all links be updated when a file is renamed
			rename_update_links = true,
		})
	end,
}
