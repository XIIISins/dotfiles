-- Left sidebar: a file tree in a scratch buffer (no plugin). <leader>e toggles it (keymaps.lua).
-- Windows belong to a single tab, so the sidebar is rebuilt in every tab while it is enabled, which
-- makes it behave as one global sidebar. Keys in the tree: <CR>/l/o open or expand, h collapse or
-- go to the parent, R refresh, q close.
local M = {}

local width = 34
local folder = "\239\129\187" -- U+F07B
local folder_open = "\239\129\188" -- U+F07C
local file = "\239\133\155" -- U+F15B

M.enabled = false
local tabs = {} -- tabpage handle -> sidebar window
local closing = false
local buf, root
local expanded = {} -- directory path -> true
local entries = {} -- buffer line -> { path, name, dir, depth }
local group = vim.api.nvim_create_augroup("sidebar", { clear = true })
local ns = vim.api.nvim_create_namespace("sidebar")

local function valid(win)
	return win and vim.api.nvim_win_is_valid(win)
end

local function set_highlights()
	local c = require("config.theme").colors()
	vim.api.nvim_set_hl(0, "SidebarTitle", { fg = c.bg_dark, bg = c.blue, bold = true })
	-- the FILES title lives in the tabline, which has the bar background
	vim.api.nvim_set_hl(0, "SidebarHeaderArrow", { fg = c.blue, bg = c.bg_dark })
	vim.api.nvim_set_hl(0, "SidebarDir", { fg = c.blue })
	vim.api.nvim_set_hl(0, "SidebarRoot", { fg = c.orange, bold = true })
end

--- windows of a tab that belong to the sidebar
function M.is_sidebar(win)
	return valid(win) and vim.w[win].sidebar == true
end

local function editing(win)
	return valid(win) and not M.is_sidebar(win) and vim.api.nvim_win_get_config(win).relative == ""
end

local function scan(dir, depth, out)
	local handle = vim.uv.fs_scandir(dir)
	if not handle then
		return
	end
	local items = {}
	while true do
		local name, kind = vim.uv.fs_scandir_next(handle)
		if not name then
			break
		end
		if kind == "link" then
			local stat = vim.uv.fs_stat(dir .. "/" .. name)
			kind = stat and stat.type or "file"
		end
		items[#items + 1] = { name = name, dir = kind == "directory" }
	end
	table.sort(items, function(a, b)
		if a.dir ~= b.dir then
			return a.dir
		end
		return a.name:lower() < b.name:lower()
	end)
	for _, item in ipairs(items) do
		local path = dir .. "/" .. item.name
		out[#out + 1] = { path = path, name = item.name, dir = item.dir, depth = depth }
		if item.dir and expanded[path] then
			scan(path, depth + 1, out)
		end
	end
end

local function line_of(path)
	for i, e in ipairs(entries) do
		if e.path == path then
			return i
		end
	end
end

--- rebuild the buffer from the filesystem, keeping each sidebar window's cursor on its entry
local function draw()
	if not (buf and vim.api.nvim_buf_is_valid(buf)) then
		return
	end
	local kept = {}
	for _, win in pairs(tabs) do
		if valid(win) then
			local e = entries[vim.api.nvim_win_get_cursor(win)[1]]
			kept[win] = e and e.path
		end
	end

	entries = { { path = root, name = vim.fs.basename(root) .. "/", dir = true, depth = 0 } }
	scan(root, 1, entries)
	local lines = {}
	for i, e in ipairs(entries) do
		local icon = file
		if e.dir then
			icon = (i == 1 or expanded[e.path]) and folder_open or folder
		end
		lines[i] = string.rep("  ", e.depth) .. icon .. " " .. e.name
	end

	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for i, e in ipairs(entries) do
		if i == 1 then
			vim.api.nvim_buf_add_highlight(buf, ns, "SidebarRoot", 0, 0, -1)
		elseif e.dir then
			vim.api.nvim_buf_add_highlight(buf, ns, "SidebarDir", i - 1, 0, -1)
		end
	end

	for win, path in pairs(kept) do
		local line = path and line_of(path) or 1
		pcall(vim.api.nvim_win_set_cursor, win, { line or 1, 0 })
	end
end

--- the window files open in: the one we came from, else any editing window
local function target_win()
	local prev = vim.fn.win_getid(vim.fn.winnr("#"))
	if editing(prev) then
		return prev
	end
	for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if editing(w) then
			return w
		end
	end
end

local function current_entry()
	return entries[vim.api.nvim_win_get_cursor(0)[1]]
end

local function open_entry()
	local e = current_entry()
	if not e then
		return
	end
	if e.dir then
		if e.path ~= root then
			expanded[e.path] = not expanded[e.path] or nil
			draw()
		end
		return
	end
	local win = target_win()
	if win then
		vim.api.nvim_set_current_win(win)
	end
	vim.cmd.edit(vim.fn.fnameescape(e.path))
end

local function collapse_or_parent()
	local e = current_entry()
	if not e then
		return
	end
	if e.dir and expanded[e.path] then
		expanded[e.path] = nil
		draw()
		return
	end
	local parent = line_of(vim.fs.dirname(e.path))
	if parent then
		vim.api.nvim_win_set_cursor(0, { parent, 0 })
	end
end

local function get_buf()
	if buf and vim.api.nvim_buf_is_valid(buf) then
		return buf
	end
	buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "hide"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false
	vim.bo[buf].filetype = "sidebar"
	vim.api.nvim_buf_set_name(buf, "sidebar://files")
	local function map(lhs, fn)
		vim.keymap.set("n", lhs, fn, { buffer = buf, silent = true, nowait = true })
	end
	for _, lhs in ipairs({ "<CR>", "l", "o" }) do
		map(lhs, open_entry)
	end
	map("h", collapse_or_parent)
	map("R", draw)
	map("q", function()
		M.close()
	end)
	return buf
end

--- close the sidebar window of one tab
local function close_tab(tab)
	local win = tabs[tab]
	tabs[tab] = nil
	if valid(win) then
		closing = true
		pcall(vim.api.nvim_win_close, win, true)
		closing = false
	end
	vim.cmd.redrawtabline()
end

--- build the sidebar in the current tab
local function build()
	local tab = vim.api.nvim_get_current_tabpage()
	if tabs[tab] then
		return
	end
	local win = vim.api.nvim_open_win(get_buf(), false, { split = "left", win = -1, width = width })
	tabs[tab] = win
	vim.w[win].sidebar = true
	for opt, value in pairs({
		number = false,
		relativenumber = false,
		signcolumn = "no",
		cursorline = true,
		wrap = false,
		winfixwidth = true,
		winfixbuf = true,
		list = false,
		statusline = " ",
	}) do
		vim.wo[win][opt] = value
	end
	draw()
	vim.cmd.redrawtabline()
end

--- expand the parents of the current file and put the cursor on it in every sidebar window
local function reveal()
	local b = vim.api.nvim_get_current_buf()
	if vim.bo[b].buftype ~= "" or not root then
		return
	end
	local path = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(b) ~= "" and vim.api.nvim_buf_get_name(b) or ".")
	local base = vim.uv.fs_realpath(root)
	if not path or not base or path:sub(1, #base + 1) ~= base .. "/" then
		return
	end
	local dirty = false
	local dir = vim.fs.dirname(path)
	while #dir > #base do
		if not expanded[dir] then
			expanded[dir] = true
			dirty = true
		end
		dir = vim.fs.dirname(dir)
	end
	if dirty then
		draw()
	end
	local line = line_of(path)
	if line then
		for _, win in pairs(tabs) do
			if valid(win) then
				pcall(vim.api.nvim_win_set_cursor, win, { line, 0 })
			end
		end
	end
end

function M.is_open()
	return M.enabled
end

--- columns taken by the sidebar in the current tab, including the separator; 0 when there is none
function M.width()
	local win = tabs[vim.api.nvim_get_current_tabpage()]
	if valid(win) then
		return vim.api.nvim_win_get_width(win) + 1
	end
	return 0
end

--- tabline text for the area above the sidebar: the FILES title, padded to the sidebar width
function M.header()
	local w = M.width()
	local label = " FILES "
	if w == 0 then
		return ""
	end
	local pad = math.max(w - vim.api.nvim_strwidth(label) - 1, 0)
	return "%#SidebarTitle#" .. label .. "%#SidebarHeaderArrow#\238\130\176%#TabLineFill#" .. string.rep(" ", pad)
end

--- jump straight to the sidebar, or back to the previous window when already in it
function M.focus()
	local win = tabs[vim.api.nvim_get_current_tabpage()]
	if not valid(win) then
		return
	end
	if M.is_sidebar(vim.api.nvim_get_current_win()) then
		vim.cmd.wincmd("p")
	else
		vim.api.nvim_set_current_win(win)
	end
end

function M.close()
	M.enabled = false
	for tab in pairs(tabs) do
		close_tab(tab)
	end
	vim.api.nvim_clear_autocmds({ group = group })
end

function M.open()
	M.enabled = true
	root = root or vim.uv.cwd()
	expanded[root] = true
	build()
	reveal()

	-- the tabline starts after the sidebar, so it has to follow resizes
	vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
		group = group,
		callback = function()
			vim.cmd.redrawtabline()
		end,
	})

	-- every tab gets its own copy
	vim.api.nvim_create_autocmd("TabEnter", {
		group = group,
		callback = function()
			vim.schedule(function()
				if M.enabled then
					build()
				end
			end)
		end,
	})
	vim.api.nvim_create_autocmd("TabClosed", {
		group = group,
		callback = function()
			for tab in pairs(tabs) do
				if not vim.api.nvim_tabpage_is_valid(tab) then
					tabs[tab] = nil
				end
			end
		end,
	})

	-- follow the file being edited, and pick up files created outside nvim
	vim.api.nvim_create_autocmd("BufEnter", { group = group, callback = reveal })
	vim.api.nvim_create_autocmd({ "FocusGained", "BufWritePost", "ShellCmdPost", "TermClose" }, {
		group = group,
		callback = function()
			vim.schedule(draw)
		end,
	})

	-- closing the sidebar window by hand turns the whole sidebar off
	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function(ev)
			if closing then
				return
			end
			local closed = tonumber(ev.match)
			for tab, win in pairs(tabs) do
				if win == closed then
					-- a tab closing takes its sidebar window along; only a window closed in a live tab counts
					vim.schedule(function()
						if vim.api.nvim_tabpage_is_valid(tab) then
							M.close()
						end
					end)
					return
				end
			end
		end,
	})

	-- quitting the last editing window of a tab removes that tab's sidebar so the tab (or nvim) can close
	vim.api.nvim_create_autocmd("QuitPre", {
		group = group,
		callback = function()
			local count = 0
			for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
				if editing(w) then
					count = count + 1
				end
			end
			if count <= 1 then
				close_tab(vim.api.nvim_get_current_tabpage())
			end
		end,
	})
end

function M.toggle()
	if M.enabled then
		M.close()
	else
		M.open()
	end
end

function M.setup()
	set_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", { group = vim.api.nvim_create_augroup("sidebar_hl", { clear = true }), callback = set_highlights })
end

return M
