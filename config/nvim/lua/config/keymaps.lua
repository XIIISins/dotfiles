local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Do things without affecting the registers
keymap.set("n", "x", '"_x')
keymap.set("n", "<Leader>p", '"0p')
keymap.set("n", "<Leader>P", '"0P')
keymap.set("v", "<Leader>p", '"0p')

-- Increment/decrement
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- Select all
keymap.set("n", "<C-a>", "gg<S-v>G")

-- Disable continuations
keymap.set("n", "<Leader>o", "o<Esc>^Da", opts)
keymap.set("n", "<Leader>O", "O<Esc>^Da", opts)

-- Save, clear search highlight, quit
keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })
keymap.set({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })
keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- Keep the selection when indenting
keymap.set("v", "<", "<gv")
keymap.set("v", ">", ">gv")

-- Find files and grep without a picker plugin
keymap.set("n", "<leader>ff", ":find ", { desc = "Find file" })
keymap.set("n", "<leader>/", ":silent grep! ", { desc = "Grep" })
keymap.set("n", "<leader>fb", ":ls<cr>:b<space>", { desc = "Buffers" })
if vim.fn.executable("rg") == 1 then
	vim.opt.grepprg = "rg --vimgrep --smart-case"
end

-- New tab
keymap.set("n", "te", ":tabedit<Return>")
keymap.set("n", "<tab>", ":tabnext<Return>", opts)
keymap.set("n", "<s-tab>", ":tabprev<Return>", opts)
keymap.set("n", "sN", ":tabnew<Return>", opts)
keymap.set("n", "sX", function()
	if vim.fn.tabpagenr("$") > 1 then
		vim.cmd.tabclose()
	else
		vim.notify("Last tab", vim.log.levels.INFO)
	end
end, opts)
-- Buffers of the current split only (see config/groups.lua)
keymap.set("n", "<S-l>", function()
	require("config.groups").cycle(1)
end, opts)
keymap.set("n", "<S-h>", function()
	require("config.groups").cycle(-1)
end, opts)
keymap.set("n", "sn", ":enew<Return>", opts) -- new empty buffer in this split (sN is a real tab)
for _, lhs in ipairs({ "sx", "<leader>bd" }) do
	keymap.set("n", lhs, function()
		require("config.groups").close()
	end, { noremap = true, silent = true, desc = "Close buffer in this split" })
end
-- Move the current split into its own tab (the sidebar is rebuilt there by TabEnter)
keymap.set("n", "st", function()
	local sidebar = require("config.sidebar")
	local editing = 0
	for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if not sidebar.is_sidebar(w) and vim.api.nvim_win_get_config(w).relative == "" then
			editing = editing + 1
		end
	end
	if sidebar.is_sidebar(vim.api.nvim_get_current_win()) or editing < 2 then
		vim.notify("Nothing to split off", vim.log.levels.INFO)
		return
	end
	vim.cmd.wincmd("T")
end, opts)
-- Split window
keymap.set("n", "ss", ":split<Return>", opts)
keymap.set("n", "sv", ":vsplit<Return>", opts)
-- Move window
keymap.set("n", "sh", "<C-w>h")
keymap.set("n", "sk", "<C-w>k")
keymap.set("n", "sj", "<C-w>j")
keymap.set("n", "sl", "<C-w>l")
keymap.set("n", "<C-h>", "<C-w>h")
keymap.set("n", "<C-j>", "<C-w>j")
keymap.set("n", "<C-k>", "<C-w>k")
keymap.set("n", "<C-l>", "<C-w>l")

-- Sidebar: toggle, and jump to it from any split (and back)
keymap.set("n", "<leader>e", function()
	require("config.sidebar").toggle()
end, { desc = "Sidebar (files)" })
keymap.set("n", "sb", function()
	require("config.sidebar").focus()
end, opts)

-- Resize window
keymap.set("n", "<C-w><left>", "<C-w><")
keymap.set("n", "<C-w><right>", "<C-w>>")
keymap.set("n", "<C-w><up>", "<C-w>+")
keymap.set("n", "<C-w><down>", "<C-w>-")
