return {
  "nvim-tree/nvim-tree.lua",
  "nvim-tree/nvim-web-devicons",
  "nvim-telescope/telescope.nvim",
  "nvim-lua/plenary.nvim",
  "nvim-lualine/lualine.nvim",
  "elkowar/yuck.vim",
  "numToStr/Comment.nvim",
  "windwp/nvim-autopairs",
  "tpope/vim-fugitive",
  "lewis6991/gitsigns.nvim",
  "tpope/vim-surround",

  {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require("bufferline").setup({})
    end
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    config = function()
      require("noice").setup({
        cmdline = { view = "cmdline_popup" },
      })
    end
  },
  {
    "goolord/alpha-nvim",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local startify = require("alpha.themes.startify")
      startify.file_icons.provider = "devicons"
      require("alpha").setup(
        startify.config
      )
    end,
  },
  {
    "neovim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = {"neovim-treesitter/treesitter-parser-registry"},
    config = function()
    end,
  },

  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {},
  },
  {
    "Saghen/blink.cmp",
    version = "1.*",
    opts = {
      keymap = {
        preset = 'default',
        ['<C-space>'] = { 'show', 'show_documentation', 'hide' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
      },
      sources = {
        default = { 'lsp', 'path', 'buffer' },
      },
    },
  },
}
