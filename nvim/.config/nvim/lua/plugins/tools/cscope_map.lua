local status_ok, cscope_maps = pcall(require, "cscope_maps")
if not status_ok then
	return
end

cscope_maps.setup({
	disable_maps = true,
	skip_input_prompt = true,
	cscope = {
		picker = "telescope",
	},
})
