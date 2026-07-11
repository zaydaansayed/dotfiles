vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("config.lazy")

vim.opt.termguicolors = true

require("nvim-tree").setup()

vim.keymap.set('n', 'e ', '<cmd>NvimTreeToggle<CR>', { desc = 'Toggle NvimTree' })
