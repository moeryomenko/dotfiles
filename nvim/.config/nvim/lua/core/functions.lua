local M = {}

-- Reload neovim config
vim.api.nvim_create_user_command("ReloadConfig", function()
	for name, _ in pairs(package.loaded) do
		if name:match("^plugins") then
			package.loaded[name] = nil
		end
	end

	dofile(vim.env.MYVIMRC)
	vim.notify("Nvim configuration reloaded!", vim.log.levels.INFO)
end, {})

-- Copy relative path
vim.api.nvim_create_user_command("CRpath", function()
	local path = vim.fn.expand("%")
	vim.fn.setreg("+", path)
	vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {})

-- Copy absolute path
vim.api.nvim_create_user_command("CApath", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {})

--- Loads a secret using the `pass` command-line tool.
--- @param secret_name string: The name of the secret to load.
--- @return string: The loaded secret.
function M.load_secret(secret_name)
	local handle = io.popen("pass " .. secret_name)
	if not handle then
		error("Failed to load secret '" .. secret_name .. "'. Error: handle cannot be created")
	end
	local result = handle:read("*a")
	handle:close()
	return result:gsub("\n", "")
end

return M
