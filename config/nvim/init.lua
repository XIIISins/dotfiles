-- Server variant: plain Neovim 0.10+, no plugin manager and nothing fetched from the network.
if vim.loader then
	vim.loader.enable()
end

require("config.options")
require("config.theme").setup()
require("config.filetypes")
require("config.statusline").setup()
require("config.tabline").setup()
require("config.groups").setup()
require("config.sidebar").setup()
require("config.keymaps")
require("config.autocmds")
