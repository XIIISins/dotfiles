-- Left sidebar: file tree on top, git status (staged/unstaged) in the middle, commit graph below.
-- <leader>e toggles it (key defined in plugins/sidebar.lua). Windows belong to a single tab, so the
-- sidebar is rebuilt in every tab while it is enabled, which makes it behave as one global sidebar.
local M = {}

M.enabled = false
local tabs = {} -- tabpage handle -> { files = win, git = win, graph = win }
local closing = false
local group = vim.api.nvim_create_augroup("sidebar", { clear = true })

local function valid(win)
	return win and vim.api.nvim_win_is_valid(win)
end

local function set_highlights()
	local c = require("tokyonight.colors").setup({ style = "moon" })
	vim.api.nvim_set_hl(0, "SidebarTitle", { fg = c.bg_dark, bg = c.blue, bold = true })
	-- winbar titles (GIT, GRAPH): transparent behind the arrow and the rest of the row
	vim.api.nvim_set_hl(0, "SidebarTitleArrow", { fg = c.blue, bg = "NONE" })
	vim.api.nvim_set_hl(0, "SidebarTitleFill", { bg = "NONE" })
	-- the FILES title lives in the tabline, which has the bar background
	vim.api.nvim_set_hl(0, "SidebarHeaderArrow", { fg = c.blue, bg = c.bg_dark })
end

local function title(win, text)
	vim.wo[win].winbar = "%#SidebarTitle# " .. text .. " %#SidebarTitleArrow#\238\130\176%#SidebarTitleFill#"
	vim.wo[win].winhighlight = "WinBar:SidebarTitleFill,WinBarNC:SidebarTitleFill"
end

local function in_git_repo()
	return vim.fn.system({ "git", "rev-parse", "--is-inside-work-tree" }):match("true") ~= nil
end

--- windows of a tab that belong to the sidebar
function M.is_sidebar(win)
	return valid(win) and vim.w[win].sidebar == true
end

local function draw_graph(win)
	if not valid(win) then
		return
	end
	vim.api.nvim_win_call(win, function()
		local view = vim.fn.winsaveview()
		vim.wo[win].winfixbuf = false
		require("gitgraph").draw({}, { all = true, max_count = 200 })
		vim.wo[win].winfixbuf = true
		vim.fn.winrestview(view)
	end)
end

--- close the sidebar windows of one tab
local function close_tab(tab)
	local wins = tabs[tab]
	tabs[tab] = nil
	if not wins then
		return
	end
	closing = true
	for _, name in ipairs({ "graph", "git", "files" }) do
		if valid(wins[name]) then
			pcall(vim.api.nvim_win_close, wins[name], true)
		end
	end
	closing = false
	vim.cmd.redrawtabline()
end

--- build the sidebar in the current tab
local function build()
	local tab = vim.api.nvim_get_current_tabpage()
	if tabs[tab] then
		return
	end
	local origin = vim.api.nvim_get_current_win()
	local height = vim.o.lines - vim.o.cmdheight - 3
	local repo = in_git_repo()
	local cmd = require("neo-tree.command")
	local wins = {}
	tabs[tab] = wins

	cmd.execute({ source = "filesystem", position = "left", dir = vim.uv.cwd(), reveal = false })
	wins.files = vim.api.nvim_get_current_win()
	-- no winbar here: the FILES title is drawn in the tabline above this pane (see M.header)

	if repo then
		-- `new`, not `split`: a split would show the same neo-tree buffer (and source) again
		vim.cmd("belowright new")
		wins.git = vim.api.nvim_get_current_win()
		cmd.execute({ source = "git_status", position = "current" })
		title(wins.git, "GIT")

		vim.cmd("belowright new")
		wins.graph = vim.api.nvim_get_current_win()
		require("gitgraph").draw({}, { all = true, max_count = 200 })
		title(wins.graph, "GRAPH")
		vim.wo[wins.graph].number = false
		vim.wo[wins.graph].relativenumber = false
		vim.wo[wins.graph].signcolumn = "no"
		vim.wo[wins.graph].cursorline = true
		vim.wo[wins.graph].winfixbuf = true
		vim.api.nvim_win_set_height(wins.files, math.floor(height * 0.4))
		vim.api.nvim_win_set_height(wins.git, math.floor(height * 0.3))
	end

	for _, w in pairs(wins) do
		vim.w[w].sidebar = true
		vim.wo[w].winfixwidth = true
	end

	if valid(origin) then
		vim.api.nvim_set_current_win(origin)
	end
	vim.cmd.redrawtabline()
end

function M.is_open()
	return M.enabled
end

--- tabline text for the area above the sidebar: the FILES title, padded to the sidebar width
function M.header()
	local width = M.width()
	local label = " FILES "
	if width == 0 then
		return ""
	end
	local pad = math.max(width - vim.api.nvim_strwidth(label) - 1, 0)
	return "%#SidebarTitle#" .. label .. "%#SidebarHeaderArrow#\238\130\176%#TabLineFill#" .. string.rep(" ", pad)
end

--- columns taken by the sidebar in the current tab, including the separator; 0 when there is none
function M.width()
	local wins = tabs[vim.api.nvim_get_current_tabpage()]
	if wins and valid(wins.files) then
		return vim.api.nvim_win_get_width(wins.files) + 1
	end
	return 0
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
	build()

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

	-- the graph is static: redraw when something may have changed
	vim.api.nvim_create_autocmd({ "FocusGained", "BufWritePost", "TermClose" }, {
		group = group,
		callback = function()
			vim.schedule(function()
				for _, wins in pairs(tabs) do
					draw_graph(wins.graph)
				end
			end)
		end,
	})

	-- closing a sidebar window by hand turns the whole sidebar off
	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function(ev)
			if closing then
				return
			end
			local closed = tonumber(ev.match)
			for tab, wins in pairs(tabs) do
				for _, w in pairs(wins) do
					if w == closed then
						-- a tab closing takes its sidebar windows along; only a window closed in a live tab counts
						vim.schedule(function()
							if vim.api.nvim_tabpage_is_valid(tab) then
								M.close()
							end
						end)
						return
					end
				end
			end
		end,
	})

	-- quitting the last editing window of a tab removes that tab's sidebar so the tab (or nvim) can close
	vim.api.nvim_create_autocmd("QuitPre", {
		group = group,
		callback = function()
			local editing = 0
			for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
				if not M.is_sidebar(w) and vim.api.nvim_win_get_config(w).relative == "" then
					editing = editing + 1
				end
			end
			if editing <= 1 then
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
