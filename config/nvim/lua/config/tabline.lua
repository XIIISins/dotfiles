-- Tabline in the style of the lualine sections (and the tmux status line, same palette): the active
-- tab is a blue number segment, then a name segment, joined by powerline arrows like NORMAL > branch.
local M = {}

local arrow = "\238\130\176" -- U+E0B0
local divider = "\238\130\177" -- U+E0B1, lualine's component separator

local function set_highlights()
	local c = require("config.theme").colors()
	local hl = vim.api.nvim_set_hl
	hl(0, "TabLineFill", { bg = c.bg_dark })
	hl(0, "TabInactive", { fg = c.fg_dark, bg = c.bg_dark })
	hl(0, "TabNumber", { fg = c.bg_dark, bg = c.blue, bold = true }) -- lualine_a
	hl(0, "TabNumberArrow", { fg = c.blue, bg = c.fg_gutter })
	hl(0, "TabName", { fg = c.blue, bg = c.fg_gutter }) -- lualine_b
	hl(0, "TabNameArrow", { fg = c.fg_gutter, bg = c.bg_dark })
	hl(0, "TabDivider", { fg = c.fg_gutter, bg = c.bg_dark })
end

-- name the tab after its editing window, never after a sidebar window
local function editing_win(tab)
	local sidebar = require("config.sidebar")
	local win = vim.api.nvim_tabpage_get_win(tab)
	if not sidebar.is_sidebar(win) then
		return win
	end
	for _, w in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
		if not sidebar.is_sidebar(w) and vim.api.nvim_win_get_config(w).relative == "" then
			return w
		end
	end
	return win
end

local function label(tab)
	local win = editing_win(tab)
	local buf = vim.api.nvim_win_get_buf(win)
	local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
	if name == "" then
		name = "[No Name]"
	end
	if vim.bo[buf].modified then
		name = name .. " ●"
	end
	return (name:gsub("%%", "%%%%"))
end

function M.render()
	local current = vim.api.nvim_get_current_tabpage()
	-- starts after the sidebar; the area above it carries the sidebar's FILES title
	local out = { require("config.sidebar").header() .. "%#TabLineFill#" }
	local tabs = vim.api.nvim_list_tabpages()
	for i, tab in ipairs(tabs) do
		local click = "%" .. i .. "T"
		if tab == current then
			out[#out + 1] = table.concat({
				click,
				"%#TabNumber# ", i, " ",
				"%#TabNumberArrow#", arrow,
				"%#TabName# ", label(tab), " ",
				"%#TabNameArrow#", arrow,
			})
		else
			out[#out + 1] = table.concat({ click, "%#TabInactive# ", i, "  ", label(tab), " " })
			-- thin divider between neighbouring inactive tabs
			if tabs[i + 1] and tabs[i + 1] ~= current then
				out[#out + 1] = "%#TabDivider#" .. divider
			end
		end
	end
	return table.concat(out) .. "%T%#TabLineFill# "
end

function M.setup()
	set_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", { group = vim.api.nvim_create_augroup("tabline", { clear = true }), callback = set_highlights })
	vim.o.showtabline = 2
	vim.o.tabline = "%!v:lua.require'config.tabline'.render()"
end

return M
