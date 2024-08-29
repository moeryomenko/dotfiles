return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		"ThePrimeagen/refactoring.nvim",
		"nvim-telescope/telescope-symbols.nvim",
		"molecule-man/telescope-menufacture",
		"debugloop/telescope-undo.nvim",
		"ThePrimeagen/harpoon",
	},
	cmd = "Telescope",
	keys = {
		{ "gf", ":Telescope git_files<CR>" },
		{ "gb", ":Telescope buffers<CR>" },
		{ "<space>g", ":Telescope live_grep<CR>" },
		{ "[e", ":lua vim.diagnostic.goto_prev()<CR>" },
		{ "]e", ":lua vim.diagnostic.goto_next()<CR>" },
		{ "<space>cd", ":Lspsaga show_line_diagnostics<CR>" },
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")
		local transform_mod = require("telescope.actions.mt").transform_mod
		local icons = require("core.icons")

		local function multiopen(prompt_bufnr, method)
			local cmd_map = {
				vertical = "vsplit",
				horizontal = "split",
				tab = "tabe",
				default = "edit",
			}
			local picker = action_state.get_current_picker(prompt_bufnr)
			local multi_selection = picker:get_multi_selection()

			if #multi_selection > 0 then
				require("telescope.pickers").on_close_prompt(prompt_bufnr)
				pcall(vim.api.nvim_set_current_win, picker.original_win_id)

				for i, entry in ipairs(multi_selection) do
					-- opinionated use-case
					local cmd = i == 1 and "edit" or cmd_map[method]
					vim.cmd(string.format("%s %s", cmd, entry.value))
				end
			else
				actions["select_" .. method](prompt_bufnr)
			end
		end

		local custom_actions = transform_mod({
			multi_selection_open_vertical = function(prompt_bufnr)
				multiopen(prompt_bufnr, "vertical")
			end,
			multi_selection_open_horizontal = function(prompt_bufnr)
				multiopen(prompt_bufnr, "horizontal")
			end,
			multi_selection_open_tab = function(prompt_bufnr)
				multiopen(prompt_bufnr, "tab")
			end,
			multi_selection_open = function(prompt_bufnr)
				multiopen(prompt_bufnr, "default")
			end,
		})

		local function stopinsert(callback)
			return function(prompt_bufnr)
				vim.cmd.stopinsert()
				vim.schedule(function()
					callback(prompt_bufnr)
				end)
			end
		end
		local multi_open_mappings = {
			i = {
				["<C-v>"] = stopinsert(custom_actions.multi_selection_open_vertical),
				["<C-x>"] = stopinsert(custom_actions.multi_selection_open_horizontal),
				["<C-t>"] = stopinsert(custom_actions.multi_selection_open_tab),
				["<CR>"] = stopinsert(custom_actions.multi_selection_open),
			},
			n = {
				["<C-v>"] = custom_actions.multi_selection_open_vertical,
				["<C-x>"] = custom_actions.multi_selection_open_horizontal,
				["<C-t>"] = custom_actions.multi_selection_open_tab,
				["<CR>"] = custom_actions.multi_selection_open,
			},
		}

		local function flash(prompt_bufnr)
			require("flash").jump({
				pattern = "^",
				label = { after = { 0, 0 } },
				search = {
					mode = "search",
					exclude = {
						function(win)
							return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "TelescopeResults"
						end,
					},
				},
				action = function(match)
					local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
					picker:set_selection(match.pos[1] - 1)
				end,
			})
		end

		telescope.setup({
			defaults = {
				layout_config = {
					height = 0.8,
					width = 0.9,
					prompt_position = "top",
					bottom_pane = {
						height = 0.5,
						preview_width = 0.6,
						preview_cutoff = 120,
					},
					center = {
						height = 0.4,
						preview_cutoff = 40,
					},
					cursor = {
						preview_cutoff = 40,
						preview_width = 0.6,
					},
					horizontal = {
						preview_width = 0.6,
						preview_cutoff = 120,
					},
					vertical = {
						preview_cutoff = 40,
					},
					-- other layout configuration here
				},
				prompt_prefix = icons.ui.Telescope .. icons.ui.ChevronRight,
				selection_caret = icons.ui.Play,
				multi_icon = icons.ui.Check,
				path_display = { "smart" },
				sorting_strategy = "ascending",

				mappings = {
					i = {
						["<esc>"] = actions.close,
						["<C-n>"] = actions.cycle_history_next,
						["<C-p>"] = actions.cycle_history_prev,

						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,

						["<C-c>"] = actions.close,

						["<Down>"] = actions.move_selection_next,
						["<Up>"] = actions.move_selection_previous,

						["<CR>"] = actions.select_default,
						["<C-x>"] = actions.select_horizontal,
						["<C-v>"] = actions.select_vertical,
						["<C-t>"] = actions.select_tab,
						["<C-s>"] = flash,

						["<C-u>"] = actions.preview_scrolling_up,
						["<C-d>"] = actions.preview_scrolling_down,

						["<PageUp>"] = actions.results_scrolling_up,
						["<PageDown>"] = actions.results_scrolling_down,

						["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
						["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
						["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
						["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
						["<C-l>"] = actions.complete_tag,
					},

					n = {
						["q"] = actions.close,
						["<esc>"] = actions.close,
						["<CR>"] = actions.select_default,
						["<C-x>"] = actions.select_horizontal,
						["<C-v>"] = actions.select_vertical,
						["<C-t>"] = actions.select_tab,
						["s"] = flash,

						["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
						["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
						["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
						["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

						["j"] = actions.move_selection_next,
						["k"] = actions.move_selection_previous,
						["H"] = actions.move_to_top,
						["M"] = actions.move_to_middle,
						["L"] = actions.move_to_bottom,

						["<Down>"] = actions.move_selection_next,
						["<Up>"] = actions.move_selection_previous,
						["gg"] = actions.move_to_top,
						["G"] = actions.move_to_bottom,

						["<C-u>"] = actions.preview_scrolling_up,
						["<C-d>"] = actions.preview_scrolling_down,

						["<PageUp>"] = actions.results_scrolling_up,
						["<PageDown>"] = actions.results_scrolling_down,

						["?"] = actions.which_key,
					},
				},
			},
			pickers = {
				find_files = { mappings = multi_open_mappings },
				git_files = { mappings = multi_open_mappings },
				oldfiles = { mappings = multi_open_mappings },
			},
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
				undo = {
					use_delta = true,
					use_custom_command = nil, -- setting this implies `use_delta = false`. Accepted format is: { "bash", "-c", "echo '$DIFF' | delta" }
					side_by_side = true,
					vim_diff_opts = { ctxlen = 0 },
					entry_format = "state #$ID, $STAT, $TIME",
					-- time_format = '%d %b %H:%M',
					mappings = {
						i = {
							["<S-cr>"] = require("telescope-undo.actions").yank_additions,
							["<C-cr>"] = require("telescope-undo.actions").yank_deletions,
							["<cr>"] = require("telescope-undo.actions").restore,
						},
					},
				},
				menufacture = {
					mappings = {
						main_menu = { [{ "i", "n" }] = "<C-,>" },
					},
				},
			},
		})

		require("telescope").load_extension("fzf")
		require("telescope").load_extension("menufacture")
		require("telescope").load_extension("undo")
		require("telescope").load_extension("harpoon")
		require("telescope").load_extension("notify")
		require("telescope").load_extension("refactoring")
	end,
}
