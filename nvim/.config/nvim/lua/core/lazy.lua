local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

local status_ok, lazy = pcall(require, "lazy")
if not status_ok then
	return
end

local icons = require("core.icons")

lazy.setup({
	root = vim.fn.stdpath("data") .. "/lazy",
	spec = {
		{ import = "plugins" },
	},
	lockfile = vim.fn.stdpath("config") .. "/lua/plugins/lock.json",
	concurrency = 16,
	git = {
		log = { "--since=3 days ago" },
		timeout = 120,
		url_format = "https://github.com/%s.git",
		filter = true,
	},
	install = { colorscheme = { "default" } },
	dev = {
		-- directory where you store your local plugin projects
		path = "~/workspace",
	},
	ui = {
		size = { width = 0.9, height = 0.8 },
		wrap = true,
		border = "rounded",
		icons = {
			cmd = icons.ui.Terminal,
			config = icons.ui.Gear,
			event = icons.ui.Electric,
			ft = icons.documents.File,
			init = icons.ui.Rocket,
			import = icons.documents.Import,
			keys = icons.ui.Keyboard,
			lazy = icons.ui.Sleep,
			loaded = icons.ui.CircleSmall,
			not_loaded = icons.ui.CircleSmallEmpty,
			plugin = icons.ui.Package,
			runtime = icons.ui.NeoVim,
			source = icons.ui.Code,
			start = icons.ui.Play,
			task = icons.ui.Check,
			list = {
				icons.ui.CircleSmall,
				icons.ui.Arrow,
				icons.ui.Star,
				icons.ui.Minus,
			},
		},
		throttle = 20,
	},
	diff = {
		-- diff command <d> can be one of:
		-- * browser: opens the github compare view. Note that this is always mapped to <K> as well,
		--   so you can have a different command for diff <d>
		-- * git: will run git diff and open a buffer with filetype git
		-- * terminal_git: will open a pseudo terminal with git diff
		-- * diffview.nvim: will open Diffview to show the diff
		cmd = "git",
	},
	checker = {
		enabled = true,
		concurrency = 16,
		notify = true,
		frequency = 3600,
	},
	change_detection = {
		enabled = true,
		notify = true,
	},
	performance = {
		cache = {
			enabled = true,
		},
		reset_packpath = true,
		rtp = {
			reset = true,
			disabled_plugins = {},
		},
	},
	readme = {
		root = vim.fn.stdpath("state") .. "/lazy/readme",
		files = { "README.md", "lua/**/README.md" },
		skip_if_doc_exists = true,
	},
	state = vim.fn.stdpath("state") .. "/lazy/state.json",
})
