local M = {}

function M.map(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

local icons = require("core.icons")

function M.setup_diagnostics()
	local diagnostics = {
		underline = true,
		update_in_insert = false,
		virtual_text = {
			spacing = 4,
			source = "if_many",
			prefix = "●",
			-- this will set set the prefix to a function that returns the diagnostics icon based on the severity
			-- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
			-- prefix = "icons",
		},
		severity_sort = true,
		signs = {
			text = {
				[vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
				[vim.diagnostic.severity.WARN] = icons.diagnostics.Warning,
				[vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
				[vim.diagnostic.severity.INFO] = icons.diagnostics.Information,
			},
		},
	}

	-- set diagnostic icons
	for name, icon in pairs(icons.diagnostics) do
		name = "DiagnosticSign" .. name
		vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
	end

	if type(diagnostics.virtual_text) == "table" and diagnostics.virtual_text.prefix == "icons" then
		diagnostics.virtual_text.prefix = "●"
			or function(diagnostic)
				for d, icon in pairs(icons.diagnostics) do
					if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
						return icon
					end
				end
			end
	end

	vim.diagnostic.config(vim.deepcopy(diagnostics))
end

return M
