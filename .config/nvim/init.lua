vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("config.lazy")

vim.opt.termguicolors = true

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'lua' },
  callback = function()
    vim.treesitter.start()
  end
})

require("nvim-tree").setup()
require('lualine').setup()

vim.keymap.set('n', 'e ', '<cmd>NvimTreeToggle<CR>', { desc = 'Toggle NvimTree' })
vim.keymap.set('n', 'es', '<cmd>Telescope find_files<CR>', { desc = 'Open telescope search' })
vim.keymap.set('n', 'ec', '<cmd>vert term<CR>', { desc = 'Open terminal' })
