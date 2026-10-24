-- TokyoNight Moon without the plugin: colours come from palette/out/tokyonight-moon.lua (generated
-- by palette/render), highlight groups are set here. The background is left transparent so the
-- terminal shows through.
local M = {}

--- palette colours by name (bg, bg_dark, blue, fg_gutter, ...); ../palette resolves through the repo
--- symlink, as in tmux.conf
function M.colors()
	local dir = vim.uv.fs_realpath(vim.fn.stdpath("config")) or vim.fn.stdpath("config")
	local ok, c = pcall(dofile, vim.fs.dirname(dir) .. "/palette/out/tokyonight-moon.lua")
	return ok and c
		or { -- palette not linked: the same Moon values
			bg = "#222436", bg_dark = "#1e2030", bg_highlight = "#2f334d", fg = "#c8d3f5", fg_dark = "#828bb8",
			comment = "#636da6", blue = "#82aaff", cyan = "#86e1fc", green = "#c3e88d", magenta = "#c099ff",
			orange = "#ff966c", red = "#ff757f", yellow = "#ffc777", fg_gutter = "#3b4261", bg_float = "#272a3d",
			selection = "#2d3f76", dim = "#6c77a6", black = "#000000",
		}
end

local function apply()
	local c = M.colors()
	local function hl(name, spec)
		vim.api.nvim_set_hl(0, name, spec)
	end
	vim.cmd.highlight("clear")
	vim.o.background = "dark"
	vim.g.colors_name = "tokyonight-moon"

	-- editor
	hl("Normal", { fg = c.fg })
	hl("NormalNC", { fg = c.fg })
	hl("NormalFloat", { fg = c.fg, bg = c.bg_float })
	hl("FloatBorder", { fg = c.blue, bg = c.bg_float })
	hl("Cursor", { fg = c.bg, bg = c.fg })
	hl("CursorLine", { bg = c.bg_highlight })
	hl("CursorLineNr", { fg = c.orange, bold = true })
	hl("LineNr", { fg = c.fg_gutter })
	hl("SignColumn", { fg = c.fg_gutter })
	hl("ColorColumn", { bg = c.bg_highlight })
	hl("EndOfBuffer", { fg = c.bg })
	hl("NonText", { fg = c.fg_gutter })
	hl("SpecialKey", { fg = c.fg_gutter })
	hl("Whitespace", { fg = c.fg_gutter })
	hl("WinSeparator", { fg = c.bg_highlight })
	hl("Folded", { fg = c.blue, bg = c.fg_gutter })
	hl("Visual", { bg = c.selection })
	hl("Search", { fg = c.fg, bg = c.selection })
	hl("IncSearch", { fg = c.black, bg = c.orange })
	hl("CurSearch", { fg = c.black, bg = c.orange })
	hl("MatchParen", { fg = c.orange, bold = true })
	hl("Directory", { fg = c.blue })
	hl("Title", { fg = c.blue, bold = true })
	hl("Pmenu", { fg = c.fg, bg = c.bg_float })
	hl("PmenuSel", { bg = c.selection })
	hl("PmenuSbar", { bg = c.bg_highlight })
	hl("PmenuThumb", { bg = c.fg_gutter })
	hl("WildMenu", { bg = c.selection })

	-- messages
	hl("ErrorMsg", { fg = c.red })
	hl("WarningMsg", { fg = c.yellow })
	hl("ModeMsg", { fg = c.fg_dark, bold = true })
	hl("MoreMsg", { fg = c.blue })
	hl("Question", { fg = c.blue })

	-- statusline, tabline
	hl("StatusLine", { fg = c.fg_dark, bg = c.bg_dark })
	hl("StatusLineNC", { fg = c.fg_gutter, bg = c.bg_dark })
	hl("TabLine", { fg = c.fg_gutter, bg = c.bg_dark })
	hl("TabLineSel", { fg = c.bg_dark, bg = c.blue })
	hl("TabLineFill", { bg = c.bg_dark })

	-- diff and spell
	hl("DiffAdd", { bg = "#2c3d3a" })
	hl("DiffChange", { bg = "#2b3351" })
	hl("DiffDelete", { bg = "#402a35" })
	hl("DiffText", { bg = c.selection })
	hl("SpellBad", { sp = c.red, undercurl = true })
	hl("SpellCap", { sp = c.yellow, undercurl = true })

	-- syntax (the regex syntax files link to these)
	hl("Comment", { fg = c.comment, italic = true })
	hl("Constant", { fg = c.orange })
	hl("String", { fg = c.green })
	hl("Character", { fg = c.green })
	hl("Number", { fg = c.orange })
	hl("Boolean", { fg = c.orange })
	hl("Float", { fg = c.orange })
	hl("Identifier", { fg = c.magenta })
	hl("Function", { fg = c.blue })
	hl("Statement", { fg = c.magenta })
	hl("Conditional", { fg = c.magenta })
	hl("Repeat", { fg = c.magenta })
	hl("Label", { fg = c.blue })
	hl("Operator", { fg = c.cyan })
	hl("Keyword", { fg = c.cyan })
	hl("Exception", { fg = c.magenta })
	hl("PreProc", { fg = c.cyan })
	hl("Include", { fg = c.blue })
	hl("Define", { fg = c.magenta })
	hl("Macro", { fg = c.blue })
	hl("Type", { fg = c.cyan })
	hl("StorageClass", { fg = c.cyan })
	hl("Structure", { fg = c.cyan })
	hl("Typedef", { fg = c.cyan })
	hl("Special", { fg = c.blue })
	hl("SpecialChar", { fg = c.orange })
	hl("Delimiter", { fg = c.fg_dark })
	hl("SpecialComment", { fg = c.comment })
	hl("Underlined", { underline = true })
	hl("Error", { fg = c.red })
	hl("Todo", { fg = c.bg, bg = c.yellow })
	hl("Added", { fg = c.green })
	hl("Changed", { fg = c.yellow })
	hl("Removed", { fg = c.red })
end

function M.setup()
	apply()
end

return M
