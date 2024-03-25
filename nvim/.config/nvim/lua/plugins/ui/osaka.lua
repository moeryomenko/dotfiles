local status_ok, osaka = pcall(require, "solarized-osaka")
if not status_ok then
	return
end

vim.cmd([[colorscheme solarized-osaka]])
