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
  {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require("bufferline").setup({})
    end
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
}
