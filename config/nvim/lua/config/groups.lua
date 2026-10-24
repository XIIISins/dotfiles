-- Editor groups: every editing split keeps its own list of buffers and shows it as a winbar, so a
-- split behaves like a tab strip of its own (as in VS Code). The tabline above still holds the real
-- tabs. A buffer joins a window's list when it is shown there; <S-h>/<S-l> cycle that list only.
local M = {}

local lists = {} -- window handle -> ordered list of buffer numbers
local group = vim.api.nvim_create_augroup("groups", { clear = true })
local arrow = "\238\130\176" -- U+E0B0

local function set_highlights()
	local c = require("tokyonight.colors").setup({ style = "moon" })
	local hl = vim.api.nvim_set_hl
	hl(0, "WinBar", { bg = c.bg_dark })
	hl(0, "WinBarNC", { bg = c.bg_dark })
	hl(0, "GroupActive", { fg = c.blue, bg = c.fg_gutter })
	hl(0, "GroupActiveArrow", { fg = c.fg_gutter, bg = c.bg_dark })
	hl(0, "GroupInactive", { fg = c.fg_dark, bg = c.bg_dark })
end

-- sidebar and tool windows (neo-tree, graph, help, terminals) are not groups
local function eligible(buf)
	return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" and vim.bo[buf].buflisted
end

local function editing(win)
	return vim.api.nvim_win_is_valid(win)
		and vim.api.nvim_win_get_config(win).relative == ""
		and not require("config.sidebar").is_sidebar(win)
end

local function index_of(list, buf)
	for i, b in ipairs(list) do
		if b == buf then
			return i
		end
	end
end

-- drop buffers that were wiped or unlisted
local function prune(win)
	local list = lists[win] or {}
	for i = #list, 1, -1 do
		if not eligible(list[i]) then
			table.remove(list, i)
		end
	end
	return list
end

local function track(win)
	if not editing(win) then
		return
	end
	local buf = vim.api.nvim_win_get_buf(win)
	if not eligible(buf) then
		if vim.wo[win].winbar:find("config.groups", 1, true) then
			vim.wo[win].winbar = ""
		end
		return
	end
	lists[win] = lists[win] or {}
	if not index_of(lists[win], buf) then
		table.insert(lists[win], buf)
	end
	vim.wo[win].winbar = "%!v:lua.require'config.groups'.render()"
end

function M.render()
	local win = vim.g.statusline_winid
	local list = prune(win)
	local current = vim.api.nvim_win_get_buf(win)
	local out = {}
	for _, buf in ipairs(list) do
		local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
		if name == "" then
			name = "[No Name]"
		end
		if vim.bo[buf].modified then
			name = name .. " ●"
		end
		name = name:gsub("%%", "%%%%")
		if buf == current then
			out[#out + 1] = "%#GroupActive# " .. name .. " %#GroupActiveArrow#" .. arrow
		else
			out[#out + 1] = "%#GroupInactive# " .. name .. " "
		end
	end
	return table.concat(out) .. "%#WinBar#"
end

--- show the next (dir = 1) or previous (dir = -1) buffer of the current window's list
function M.cycle(dir)
	local win = vim.api.nvim_get_current_win()
	local list = prune(win)
	local i = index_of(list, vim.api.nvim_win_get_buf(win))
	if not i or #list < 2 then
		return
	end
	vim.api.nvim_win_set_buf(win, list[(i - 1 + dir) % #list + 1])
end

--- close the current buffer in this window's list; the buffer itself is only deleted when no other
--- window lists it
function M.close()
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(win)
	local list = prune(win)
	local i = index_of(list, buf)
	if not i then
		vim.cmd("confirm bdelete")
		return
	end

	local shared = false
	for w, l in pairs(lists) do
		if w ~= win and vim.api.nvim_win_is_valid(w) and index_of(prune(w), buf) then
			shared = true
		end
	end

	if #list == 1 then
		local others = 0
		for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			if w ~= win and editing(w) then
				others = others + 1
			end
		end
		if others > 0 then
			table.remove(lists[win], i)
			vim.api.nvim_win_close(win, false)
		else
			vim.cmd("confirm bdelete")
		end
		return
	end

	table.remove(list, i)
	vim.api.nvim_win_set_buf(win, list[math.min(i, #list)])
	if not shared then
		pcall(vim.cmd, "confirm bdelete " .. buf)
		-- cancelled (unsaved changes): keep it in the list and on screen
		if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
			table.insert(list, i, buf)
			vim.api.nvim_win_set_buf(win, buf)
		end
	end
	vim.cmd.redrawstatus({ bang = true })
end

function M.setup()
	set_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_highlights })
	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinNew" }, {
		group = group,
		callback = function()
			track(vim.api.nvim_get_current_win())
		end,
	})
	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function(ev)
			lists[tonumber(ev.match)] = nil
		end,
	})
	-- the winbar of every window showing a changed buffer has to follow modified flags and renames
	vim.api.nvim_create_autocmd({ "BufModifiedSet", "BufFilePost" }, {
		group = group,
		callback = function()
			vim.cmd.redrawstatus({ bang = true })
		end,
	})
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		track(win)
	end
end

return M
