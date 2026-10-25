-- a machine can replace the dashboard header with $XDG_CONFIG_HOME/local/nvim/dashboard-header.txt,
-- which lives outside the repo (e.g. the work banner). ":h" is lexical, so this is ~/.config and not
-- the repo's config/ behind the nvim symlink.
local function dashboard_header()
	local path = vim.fn.fnamemodify(vim.fn.stdpath("config"), ":h") .. "/local/nvim/dashboard-header.txt"
	if vim.fn.filereadable(path) == 1 then
		return table.concat(vim.fn.readfile(path), "\n")
	end
	return [[
██╗  ██╗██╗██╗██╗███████╗██╗███╗   ██╗███████╗
╚██╗██╔╝██║██║██║██╔════╝██║████╗  ██║██╔════╝
 ╚███╔╝ ██║██║██║███████╗██║██╔██╗ ██║███████╗
 ██╔██╗ ██║██║██║╚════██║██║██║╚██╗██║╚════██║
██╔╝ ██╗██║██║██║███████║██║██║ ╚████║███████║
╚═╝  ╚═╝╚═╝╚═╝╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝
   ]]
end

return {
	-- messages, cmdline and the popupmenu
	{
		"folke/noice.nvim",
		opts = function(_, opts)
			table.insert(opts.routes, {
				filter = {
					event = "notify",
					find = "No information available",
				},
				opts = { skip = true },
			})
			local focused = true
			vim.api.nvim_create_autocmd("FocusGained", {
				callback = function()
					focused = true
				end,
			})
			vim.api.nvim_create_autocmd("FocusLost", {
				callback = function()
					focused = false
				end,
			})
			table.insert(opts.routes, 1, {
				filter = {
					cond = function()
						return not focused
					end,
				},
				view = "notify_send",
				opts = { stop = false },
			})

			opts.commands = {
				all = {
					-- options for the message history that you get with `:Noice`
					view = "split",
					opts = { enter = true, format = "details" },
					filter = {},
				},
			}

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function(event)
					vim.schedule(function()
						require("noice.text.markdown").keys(event.buf)
					end)
				end,
			})

			opts.presets.lsp_doc_border = true
		end,
	},

	{
		"rcarriga/nvim-notify",
		opts = {
			timeout = 5000,
		},
	},

	-- tabs are drawn by config/tabline.lua, in the style of the lualine sections
	{ "akinsho/bufferline.nvim", enabled = false },

	-- statusline
	{
		"nvim-lualine/lualine.nvim",
		opts = function(_, opts)
			local LazyVim = require("lazyvim.util")
			opts.sections.lualine_c[4] = {
				LazyVim.lualine.pretty_path({
					length = 0,
					relative = "cwd",
					modified_hl = "MatchParen",
					directory_hl = "",
					filename_hl = "Bold",
					modified_sign = "",
					readonly_icon = " 󰌾 ",
				}),
			}
		end,
	},

	{
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		opts = {
			plugins = {
				gitsigns = true,
				tmux = true,
				kitty = { enabled = false, font = "+2" },
			},
		},
		keys = { { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" } },
	},

	-- Markdown is rendered in the buffer (headings, tables, code, checkboxes); only the cursor line shows
	-- raw syntax. render_modes keeps it rendered in insert mode too, which makes editing near-WYSIWYG.
	{
		"MeanderingProgrammer/render-markdown.nvim",
		opts = function(_, opts)
			-- underlined, bold headings in palette colours: a terminal can't size text, so this is what
			-- marks a heading as one
			local function set_heading_hl()
				local c = require("tokyonight.colors").setup({ style = "moon" })
				local palette = { c.blue, c.magenta, c.cyan, c.green, c.yellow, c.orange }
				for i, fg in ipairs(palette) do
					vim.api.nvim_set_hl(0, "MarkdownHeading" .. i, { fg = fg, bold = true, underline = true })
				end
			end
			set_heading_hl()
			vim.api.nvim_create_autocmd("ColorScheme", { callback = set_heading_hl })

			opts.render_modes = true
			-- no level icons: the # signs stay, which reads better than a glyph
			opts.heading = { icons = {}, sign = false, foregrounds = {} }
			for i = 1, 6 do
				opts.heading.foregrounds[i] = "MarkdownHeading" .. i
			end
		end,
	},
	-- the browser preview is replaced by the in-buffer rendering
	{ "iamcco/markdown-preview.nvim", enabled = false },

	{
		"folke/snacks.nvim",
		opts = function(_, opts)
			-- "n" on the dashboard (plain `vi`) starts a new file with the sidebar open; `vi <file>` has no dashboard
			for _, item in ipairs(vim.tbl_get(opts, "dashboard", "preset", "keys") or {}) do
				if item.key == "n" then
					item.action = function()
						if not require("config.sidebar").is_open() then
							require("config.sidebar").open()
						end
						vim.cmd("enew | startinsert")
					end
				end
			end
		end,
	},
	{
		"folke/snacks.nvim",
		opts = {
			scroll = { enabled = false },
			dashboard = {
				preset = {
					header = dashboard_header(),
				},
			},
		},
	},
}
