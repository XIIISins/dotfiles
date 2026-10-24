-- Built-in (regex) syntax highlighting; this only adds the file types and settings that yaml, shell
-- and python files on servers need.
vim.filetype.add({
	extension = { yml = "yaml", yaml = "yaml", sh = "sh", bash = "bash", zsh = "zsh" },
	filename = { [".env"] = "sh", ["authorized_keys"] = "conf", [".bash_aliases"] = "bash" },
	pattern = {
		-- templated yaml (ansible, helm values) is still yaml
		[".*%.ya?ml%.j2"] = "yaml",
		[".*%.env%..*"] = "sh",
	},
})

-- the bundled sh syntax highlights bash constructs only when told the dialect
vim.g.is_bash = 1
-- richer highlighting from the bundled python syntax (builtins, exceptions, operators)
vim.g.python_highlight_all = 1

local group = vim.api.nvim_create_augroup("filetypes", { clear = true })
local settings = {
	yaml = { shiftwidth = 2, tabstop = 2, expandtab = true, indentkeys = "0#,0},0],!^F,o,O,e" },
	sh = { shiftwidth = 2, tabstop = 2, expandtab = true },
	bash = { shiftwidth = 2, tabstop = 2, expandtab = true },
	python = { shiftwidth = 4, tabstop = 4, expandtab = true, colorcolumn = "88" },
	make = { expandtab = false },
}
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = vim.tbl_keys(settings),
	callback = function(ev)
		for opt, value in pairs(settings[ev.match]) do
			vim.opt_local[opt] = value
		end
	end,
})
