-- Turn off paste mode when leaving insert
vim.api.nvim_create_autocmd("InsertLeave", {
	pattern = "*",
	command = "set nopaste",
})

-- Disable the concealing in some file formats
-- The default conceallevel is 3 in LazyVim
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "json", "jsonc", "markdown" },
	callback = function()
		vim.opt.conceallevel = 0
	end,
})

-- Dim nvim while its tmux pane (or the terminal window) is unfocused. tmux can only dim cells with
-- default colours, so blend every highlight colour toward the background on FocusLost and
-- restore on FocusGained. Only in tmux, where focus events come from `focus-events on`.
if vim.env.TMUX then
	local strength = 0.5 -- 0 = invisible, 1 = no dimming
	local saved

	local function blend(fg, bg)
		local function ch(shift)
			local f, b = bit.band(bit.rshift(fg, shift), 0xff), bit.band(bit.rshift(bg, shift), 0xff)
			return math.floor(b + (f - b) * strength + 0.5)
		end
		return ch(16) * 0x10000 + ch(8) * 0x100 + ch(0)
	end

	local function dim()
		if saved then
			return
		end
		-- transparent colorschemes have no Normal bg; fall back to tokyonight moon
		local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg or 0x222436
		saved = {}
		for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
			if (hl.fg or hl.bg) and not hl.link then
				saved[name] = hl
				-- bg too: powerline arrows are glyphs drawn with their fg next to blocks drawn with their bg
				vim.api.nvim_set_hl(
					0,
					name,
					vim.tbl_extend("force", hl, {
						fg = hl.fg and blend(hl.fg, bg) or nil,
						bg = hl.bg and blend(hl.bg, bg) or nil,
					})
				)
			end
		end
	end

	local function restore()
		if not saved then
			return
		end
		for name, hl in pairs(saved) do
			vim.api.nvim_set_hl(0, name, hl)
		end
		saved = nil
	end

	local group = vim.api.nvim_create_augroup("focus_dim", { clear = true })
	vim.api.nvim_create_autocmd("FocusLost", { group = group, callback = dim })
	vim.api.nvim_create_autocmd("FocusGained", { group = group, callback = restore })
	-- a new colorscheme replaces the saved colours
	vim.api.nvim_create_autocmd("ColorSchemePre", { group = group, callback = restore })
end

-- Tabline (replaces bufferline)
require("config.tabline").setup()

-- Sidebar: files, git status, commit graph
require("config.sidebar").setup()
