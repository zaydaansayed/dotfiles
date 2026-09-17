return {
  "nvim-tree/nvim-web-devicons",
  "nvim-lua/plenary.nvim",
  "MunifTanjim/nui.nvim",
  {
    "rcarriga/nvim-notify",
    config = function()
      require("notify").setup({
        background_colour = "#151020",
      })
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
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
        ensure_installed = { "lua", "bash", "markdown", "markdown_inline" },
        highlight = { enable = true },
      })
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
                    library = vim.api.nvim_get_runtime_file("", true),
                    checkThirdParty = false,
                  },
                },
              },
            })
          end,
        },
      })
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    config = function()
      local p = require("config.theme").palette
      local wallpaper = {
        normal = {
          a = { bg = p.violet, fg = p.bg, gui = "bold" },
          b = { bg = p.surface, fg = p.fg },
          c = { bg = "NONE", fg = p.muted },
        },
        insert = {
          a = { bg = p.teal, fg = p.bg, gui = "bold" },
          b = { bg = p.surface, fg = p.fg },
          c = { bg = "NONE", fg = p.muted },
        },
        visual = {
          a = { bg = p.peach, fg = p.bg, gui = "bold" },
          b = { bg = p.surface, fg = p.fg },
          c = { bg = "NONE", fg = p.muted },
        },
        replace = {
          a = { bg = p.brick, fg = p.bg, gui = "bold" },
          b = { bg = p.surface, fg = p.fg },
          c = { bg = "NONE", fg = p.muted },
        },
        command = {
          a = { bg = p.pink, fg = p.bg, gui = "bold" },
          b = { bg = p.surface, fg = p.fg },
          c = { bg = "NONE", fg = p.muted },
        },
        inactive = {
          a = { bg = p.surface, fg = p.muted },
          b = { bg = p.surface, fg = p.muted },
          c = { bg = "NONE", fg = p.muted },
        },
      }
      require("lualine").setup({
        options = {
          theme = wallpaper,
          section_separators = "",
          component_separators = "|",
        },
      })
    end,
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    config = function()
      local p = require("config.theme").palette
      require("bufferline").setup({
        options = {
          separator_style = "thin",
          show_buffer_close_icons = false,
        },
        highlights = {
          fill = { bg = "NONE", fg = p.muted },
          background = { bg = "NONE", fg = p.muted },
          buffer_selected = { bg = "NONE", fg = p.fg, bold = true },
          buffer_visible = { bg = "NONE", fg = p.fg },
          separator = { bg = "NONE", fg = p.muted },
          separator_selected = { bg = "NONE", fg = p.violet },
          indicator_selected = { bg = "NONE", fg = p.violet },
          tab_selected = { bg = "NONE", fg = p.peach, bold = true },
          numbers_selected = { bg = "NONE", fg = p.peach, bold = true },
          modified = { bg = "NONE", fg = p.orange },
          modified_selected = { bg = "NONE", fg = p.orange },
          error = { bg = "NONE", fg = p.brick },
          error_selected = { bg = "NONE", fg = p.brick, bold = true },
          warning = { bg = "NONE", fg = p.orange },
          warning_selected = { bg = "NONE", fg = p.orange, bold = true },
          hint = { bg = "NONE", fg = p.teal },
        },
      })
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = { highlight = "IblIndent" },
      scope = { highlight = "IblScope" },
    },
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
  },
  {
    "giusgad/pets.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "giusgad/hologram.nvim" },
  },
}
