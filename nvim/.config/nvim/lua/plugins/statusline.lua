local function filetype()
	local ft = vim.bo.filetype
	local lang_icons = {
		["c"] = "",
		["cpp"] = "",
		["go"] = "",
		["rust"] = "",
		["json"] = "",
		["yaml"] = "",
		["dockerfile"] = "",
		["helm"] = "⎈",
		["lua"] = "",
		["css"] = "",
		["asm"] = "",
		["toml"] = "",
		["glsl"] = "",
		["python"] = "",
		["ruby"] = "",
		["html"] = "",
		["java"] = "",
		["sh"] = "",
		["fish"] = "",
		["javascript"] = "",
		["typescript"] = "",
		["scala"] = "",
		["clojure"] = "",
		["markdown"] = "",
		["qml"] = "",
		["terraform"] = "",
	}
	return string.format(" %s ", lang_icons[ft] or ""):upper()
end

return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "echasnovski/mini.icons" },
	config = function()
		require("lualine").setup({
			options = {
				icons_enabled = false,
				theme = "auto",
				component_separators = "",
				section_separators = "",
			},

			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch" },
				lualine_c = { "filename" },
				lualine_x = {
					function()
						local encoding = vim.o.fileencoding
						if encoding == "" then
							return vim.bo.fileformat .. " :: " .. filetype()
						else
							return encoding .. " :: " .. vim.bo.fileformat .. " :: " .. filetype()
						end
					end,
				},
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		})
	end,
}
