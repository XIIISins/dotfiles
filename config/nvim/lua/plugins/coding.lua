return {
	-- Incremental rename
	{
		"smjonas/inc-rename.nvim",
		cmd = "IncRename",
		config = true,
	},

	-- Go forward/backward with square brackets
	{
		"nvim-mini/mini.bracketed",
		event = "BufReadPost",
		config = function()
			local bracketed = require("mini.bracketed")
			bracketed.setup({
				file = { suffix = "" },
				window = { suffix = "" },
				quickfix = { suffix = "" },
				yank = { suffix = "" },
				treesitter = { suffix = "n" },
			})
		end,
	},

	-- Claude ghost-text completions (needs ANTHROPIC_API_KEY)
	{
		"milanglacier/minuet-ai.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = "InsertEnter",
		opts = {
			provider = "claude",
			provider_options = {
				claude = {
					model = "claude-haiku-5-5",
					-- Haiku 5.5 thinks by default and thinking counts toward max_tokens
					max_tokens = 1024,
					-- a JSON schema keeps reasoning out of the reply; unpacked in config below
					optional = {
						output_config = {
							effort = "low",
							format = {
								type = "json_schema",
								schema = {
									type = "object",
									properties = {
										completions = { type = "array", items = { type = "string" } },
									},
									required = { "completions" },
									additionalProperties = false,
								},
							},
						},
					},
					-- minuet's prompt and examples teach the <endCompletion> format; rewrite them for JSON
					system = {
						guidelines = function()
							return (
								require("minuet.config").default_system.guidelines:gsub(
									vim.pesc("Return completions separated by the marker <endCompletion>."),
									"Return each completion as its own string in the completions array."
								)
							)
						end,
					},
					few_shots = function()
						local shots = vim.deepcopy(require("minuet.config").default_few_shots)
						for _, shot in ipairs(shots) do
							if shot.role == "assistant" then
								local items = {}
								for _, item in ipairs(vim.split(shot.content, "<endCompletion>", { plain = true })) do
									item = item:gsub("^\n+", ""):gsub("\n+$", "")
									if item ~= "" then
										table.insert(items, item)
									end
								end
								shot.content = vim.json.encode({ completions = items })
							end
						end
						return shots
					end,
				},
			},
			virtualtext = {
				auto_trigger_ft = { "*" },
				show_on_completion_menu = true,
				keymap = {
					accept = "<C-l>",
					accept_line = "<M-l>",
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-]>",
				},
			},
		},
		config = function(_, opts)
			require("minuet").setup(opts)
			-- minuet expects completions split by <endCompletion>; read Claude's JSON instead
			local common = require("minuet.backends.common")
			local split = common.parse_completion_items
			common.parse_completion_items = function(raw, provider)
				if not raw:match("^%s*{") then
					return split(raw, provider)
				end
				local ok, decoded = pcall(vim.json.decode, raw)
				-- a reply cut off by request_timeout is partial JSON: show nothing
				if not ok or type(decoded) ~= "table" or type(decoded.completions) ~= "table" then
					return {}
				end
				-- still split a string that packs several options, and drop echoed markers
				local items = {}
				for _, completion in ipairs(decoded.completions) do
					for _, item in ipairs(split(completion, provider)) do
						item = item:gsub("<cursorPosition>", "")
						if vim.trim(item) ~= "" then
							table.insert(items, item)
						end
					end
				end
				return items
			end
			-- let LazyVim's <Tab> accept the suggestion
			LazyVim.cmp.actions.ai_accept = function()
				local action = require("minuet.virtualtext").action
				if action.is_visible() then
					LazyVim.create_undo()
					action.accept()
					return true
				end
			end
		end,
	},
}
