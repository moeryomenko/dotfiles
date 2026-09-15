local M = {}

M.neotest_adapters = {}

local function hooks(ev)
	local name, kind = ev.data.spec.name, ev.data.kind
	if not (kind == "install" or kind == "update") then
		return
	end

	if name == "telescope-fzf-native.nvim" then
		vim.system({ "make" }, { cwd = ev.data.path }):wait()
	elseif name == "nvim-treesitter" then
		vim.cmd("packadd nvim-treesitter")
		pcall(vim.cmd, "TSUpdate")
	end
end

vim.api.nvim_create_autocmd("PackChanged", { callback = hooks })

local modules = {
	"plugins.blame",
	"plugins.conform",
	"plugins.dap",
	"plugins.luasnip",
	"plugins.neotest",
	"plugins.notify",
	"plugins.nvimtree",
	"plugins.statusline",
	"plugins.surround",
	"plugins.telescope",
	"plugins.tmux",
	"plugins.treesitter",
	"lang.go",
}

function M.setup()
	local specs = {}
	local configs = {}

	for _, mod in ipairs(modules) do
		local ok, result = pcall(require, mod)
		if not ok then
			vim.notify(("plugin spec '%s': %s"):format(mod, result), vim.log.levels.ERROR)
		elseif type(result) == "table" then
			for _, item in ipairs(result) do
				local spec = type(item) == "string" and { src = item } or vim.deepcopy(item)
				if spec.config then
					configs[#configs + 1] = spec.config
					spec.config = nil
				end
				spec.build = nil
				specs[#specs + 1] = spec
			end
		end
	end

	vim.pack.add(specs, { load = true })

	for _, fn in ipairs(configs) do
		local ok, err = pcall(fn)
		if not ok then
			vim.notify("plugin config: " .. tostring(err), vim.log.levels.ERROR)
		end
	end
end

function M.update()
	vim.pack.update()
end

return M
