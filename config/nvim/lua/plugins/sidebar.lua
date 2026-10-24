-- Left sidebar (config/sidebar.lua lays these out): files, git status, commit graph
return {
	-- LazyVim's snacks explorer would own <leader>e; this sidebar replaces it
	{
		"folke/snacks.nvim",
		opts = { explorer = { enabled = false } },
		keys = { { "<leader>e", false }, { "<leader>E", false }, { "<leader>fe", false }, { "<leader>fE", false } },
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		cmd = "Neotree",
		keys = {
			{
				"<leader>e",
				function()
					require("config.sidebar").toggle()
				end,
				desc = "Sidebar (files, git, graph)",
			},
		},
		dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", "nvim-tree/nvim-web-devicons" },
		opts = {
			sources = { "filesystem", "git_status" },
			enable_diagnostics = false,
			open_files_do_not_replace_types = { "terminal", "qf", "help", "neo-tree", "gitgraph" },
			filesystem = {
				bind_to_cwd = false,
				follow_current_file = { enabled = true },
				use_libuv_file_watcher = true,
				filtered_items = { hide_dotfiles = false, hide_gitignored = false },
			},
			window = {
				width = 34,
				mappings = { ["l"] = "open", ["h"] = "close_node", ["<space>"] = "none" },
			},
		},
	},
	{ "sindrets/diffview.nvim", cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" } },
	{
		"isakbm/gitgraph.nvim",
		lazy = true,
		opts = {
			hooks = {
				-- <CR> on a commit opens its diff, visual <CR> a range
				on_select_commit = function(commit)
					vim.cmd("DiffviewOpen " .. commit.hash .. "^!")
				end,
				on_select_range_commit = function(from, to)
					vim.cmd("DiffviewOpen " .. from.hash .. "~1.." .. to.hash)
				end,
			},
			symbols = { merge_commit = "●", commit = "●" },
			format = {
				timestamp = "%H:%M:%S %d-%m-%Y",
				fields = { "hash", "branch_name", "tag" }, -- the sidebar is narrow; the message is on the next line
			},
		},
	},
}
