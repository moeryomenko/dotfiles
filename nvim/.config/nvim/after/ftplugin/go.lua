vim.keymap.set("n", "<localleader>fs", function()
	vim.lsp.buf.code_action({
		filter = function(x)
			return x.kind == "refactor.rewrite.fillStruct"
		end,
	})
end, {
	buffer = true,
})

vim.keymap.set("n", "<localleader>fS", function()
	vim.lsp.buf.code_action({
		apply = true,
		filter = function(x)
			return x.kind == "refactor.rewrite.fillStruct"
		end,
	})
end, {
	buffer = true,
})
