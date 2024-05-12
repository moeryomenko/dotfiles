return {
	"nvimdev/lspsaga.nvim",
	event = "LspAttach",
	config = function()
		local icons = require("core.icons")
		require("lspsaga").setup({
			ui = {
				-- Currently, only the round theme exists
				theme = "round",
				-- This option only works in Neovim 0.9
				border = "rounded",
				devicon = true,
				title = true,
				winblend = 1,
				expand = icons.ui.ArrowOpen,
				collapse = icons.ui.ArrowClosed,
				preview = icons.ui.List,
				code_action = icons.diagnostics.Hint,
				diagnostic = icons.ui.Bug,
				incoming = icons.ui.Incoming,
				outgoing = icons.ui.Outgoing,
				hover = icons.ui.Comment,
			},
		})
	end,
}
