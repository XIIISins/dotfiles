-- Statusline in the style of the tmux one (same palette): a mode segment, then the file, joined by
-- powerline arrows. Replaces lualine; one global line (laststatus = 3).
local M = {}

local arrow = "\238\130\176" -- U+E0B0
local lock = "\243\176\140\190" -- U+F033E

local modes = {
	n = { "NORMAL", "blue" },
	i = { "INSERT", "green" },
	v = { "VISUAL", "magenta" },
	V = { "V-LINE", "magenta" },
	["\22"] = { "V-BLOCK", "magenta" },
	c = { "COMMAND", "orange" },
	R = { "REPLACE", "red" },
	t = { "TERMINAL", "orange" },
}

local function set_highlights()
	local c = require("config.theme").colors()
	for mode, color in pairs({ blue = c.blue, green = c.green, magenta = c.magenta, orange = c.orange, red = c.red }) do
		vim.api.nvim_set_hl(0, "StlMode" .. mode, { fg = c.bg_dark, bg = color, bold = true })
		vim.api.nvim_set_hl(0, "StlModeArrow" .. mode, { fg = color, bg = c.fg_gutter })
	end
	vim.api.nvim_set_hl(0, "StlFile", { fg = c.blue, bg = c.fg_gutter })
	vim.api.nvim_set_hl(0, "StlFileArrow", { fg = c.fg_gutter, bg = c.bg_dark })
	vim.api.nvim_set_hl(0, "StlRest", { fg = c.fg_dark, bg = c.bg_dark })
end

function M.render()
	local mode = modes[vim.fn.mode()] or modes.n
	local color = mode[2]
	local flags = (vim.bo.modified and " ●" or "") .. (vim.bo.readonly and " " .. lock or "")
	return table.concat({
		"%#StlMode", color, "# ", mode[1], " ",
		"%#StlModeArrow", color, "#", arrow,
		"%#StlFile# %f", flags, " ",
		"%#StlFileArrow#", arrow,
		"%#StlRest#%=%y  %l:%c  %p%% ",
	})
end

function M.setup()
	set_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", { group = vim.api.nvim_create_augroup("statusline", { clear = true }), callback = set_highlights })
	vim.o.statusline = "%!v:lua.require'config.statusline'.render()"
end

return M
