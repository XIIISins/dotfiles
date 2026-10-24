vim.g.mapleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true

vim.opt.title = true
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.confirm = true
vim.opt.cmdheight = 0
vim.opt.laststatus = 3
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.shiftround = true
vim.opt.smartindent = true
vim.opt.scrolloff = 10
vim.opt.backupskip = { "/tmp/*", "/private/tmp/*" }
vim.opt.inccommand = "split"
vim.opt.ignorecase = true -- Case insensitive searching UNLESS /C or capital in search
vim.opt.smartcase = true
vim.opt.breakindent = true
vim.opt.wrap = false -- No Wrap lines
vim.opt.path:append({ "**" }) -- Finding files - Search down into subfolders
vim.opt.wildignore:append({ "*/node_modules/*", "*/.git/*" })
vim.opt.splitbelow = true -- Put new windows below current
vim.opt.splitright = true -- Put new windows right of current
vim.opt.splitkeep = "cursor"
vim.opt.mouse = ""
vim.opt.timeoutlen = 300
vim.opt.updatetime = 250
vim.opt.virtualedit = "block"
vim.opt.pumheight = 10

-- Over ssh there is no clipboard tool: yank through OSC 52 to the terminal you ssh from, which
-- tmux passes on (set-clipboard on). Pasting reads the unnamed register, as terminals rarely
-- answer OSC 52 reads.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
	local osc52 = require("vim.ui.clipboard.osc52")
	local function paste()
		return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
	end
	vim.g.clipboard = {
		name = "OSC 52",
		copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
		paste = { ["+"] = paste, ["*"] = paste },
	}
	vim.opt.clipboard = "unnamedplus"
end
