-- Theme option helper: returns the linked theme's opts table,
-- or {} (plugin defaults) when no theme.lua is linked (default_dark).
local function theme_opts(key)
	local ok, theme = pcall(require, "config.theme")
	if ok and theme[key] then return theme[key]() end
	return {}
end

return {
	"nvim-tree/nvim-web-devicons",
	"nvim-lua/plenary.nvim",
	"MunifTanjim/nui.nvim",
	{
		"rcarriga/nvim-notify",
		config = function()
			require("notify").setup(theme_opts("notify_opts"))
		end,
	},

	{
		"nvim-tree/nvim-tree.lua",
		config = function()
			local api = require("nvim-tree.api")

			require("nvim-tree").setup({})
		end,
	},
	{
		"elkowar/yuck.vim"
	},

	{
		"lewis6991/gitsigns.nvim",
		opts = {},
	},

	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"saadparwaiz1/cmp_luasnip",
		},
	},
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		build = "make install_jsregexp",
		dependencies = { "rafamadriz/friendly-snippets" },
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},

	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			require("mason").setup({
				firewall = { enabled = true },
			})

			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			require("mason-lspconfig").setup({
				-- NOTE: clangd is NOT installed via Mason here on purpose:
				-- you already have clangd 22 at /usr/bin/clangd and Mason
				-- needs the `unzip` binary to download packages.
				-- lspconfig below still starts clangd from your PATH.
				ensure_installed = { "bashls", "lua_ls", "marksman" },
				handlers = {
					function(server_name)
						require("lspconfig")[server_name].setup({
							capabilities = capabilities,
						})
					end,
					["lua_ls"] = function()
						require("lspconfig").lua_ls.setup({
							capabilities = capabilities,
							settings = {
								Lua = {
									diagnostics = { globals = { "vim" } },
									workspace = {
										library = vim.api.nvim_get_runtime_file(
										"", true),
										checkThirdParty = false,
									},
								},
							},
						})
					end,
					["clangd"] = function()
						require("lspconfig").clangd.setup({
							capabilities = capabilities,
							cmd = {
								"clangd",
								"--background-index",
								"--clang-tidy",
								"--header-insertion=iwyu",
								"--completion-style=detailed",
								"--function-arg-placeholders",
								"--fallback-style=llvm",
							},
							root_markers = {
								".clangd",
								".clang-tidy",
								".clang-format",
								"compile_commands.json",
								"compile_flags.txt",
								"build",
								".git",
							},
							init_options = {
								usePlaceholders = true,
								completeUnimported = true,
								clangdFileStatus = true,
							},
						})
					end,
				},
			})

			-- Global LSP keymaps (C++-relevant: gd/gr/K/rename/code-action)
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
				callback = function(ev)
					local opts = { buffer = ev.buf, silent = true }
					vim.keymap.set("n", "gd", vim.lsp.buf.definition,
						vim.tbl_extend("force", opts, { desc = "LSP: goto definition" }))
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration,
						vim.tbl_extend("force", opts, { desc = "LSP: goto declaration" }))
					vim.keymap.set("n", "gr", vim.lsp.buf.references,
						vim.tbl_extend("force", opts, { desc = "LSP: references" }))
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation,
						vim.tbl_extend("force", opts, { desc = "LSP: implementation" }))
					vim.keymap.set("n", "K", vim.lsp.buf.hover,
						vim.tbl_extend("force", opts, { desc = "LSP: hover" }))
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,
						vim.tbl_extend("force", opts, { desc = "LSP: rename" }))
					vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action,
						vim.tbl_extend("force", opts, { desc = "LSP: code action" }))
					vim.keymap.set("n", "<leader>f", function()
						require("conform").format({ async = false, lsp_format = "fallback" })
					end, vim.tbl_extend("force", opts, { desc = "Format buffer" }))
					-- clangd-only: switch source/header
					vim.keymap.set("n", "<leader>ch", "<cmd>LspClangdSwitchSourceHeader<CR>",
						vim.tbl_extend("force", opts, { desc = "Clangd: switch source/header" }))
				end,
			})
		end,
	},

	-- Treesitter parsers for C/C++ (Nvim 0.12 built-in treesitter still
	-- needs parsers; main branch is required on 0.11+)
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").install({
				"c", "cpp", "cmake", "make", "bash", "lua",
				"vim", "vimdoc", "markdown", "markdown_inline", "json",
			})
		end,
	},
	-- Debugging: nvim-dap + UI + Mason adapter installer
	{
		"mfussenegger/nvim-dap",
	},
	{
		"nvim-neotest/nvim-nio",
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		config = function()
			local dap, dapui = require("dap"), require("dapui")
			dapui.setup()
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end
		end,
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = { "mason-org/mason.nvim", "mfussenegger/nvim-dap" },
		-- codelldb (LLDB-based) as the primary debugger; system gdb
		-- via native DAP stays as fallback (see lua/config/cpp.lua).
		opts = {
			ensure_installed = { "codelldb" },
			handlers = {},
		},
	},

	{
		"nvim-lualine/lualine.nvim",
		config = function()
			require("lualine").setup(theme_opts("lualine_opts"))
		end,
	},
	{
		"akinsho/bufferline.nvim",
		version = "*",
		config = function()
			require("bufferline").setup(theme_opts("bufferline_opts"))
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		config = function()
			require("ibl").setup(theme_opts("ibl_opts"))
		end,
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
				inc_rename = false,
				lsp_doc_border = false,
			},
		},
	},
	{
		"goolord/alpha-nvim",
		config = function()
			local startify = require("alpha.themes.startify")
			startify.file_icons.provider = "devicons"
			require("alpha").setup(startify.config)
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		version = "*",
		dependencies = {
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
	}
}
