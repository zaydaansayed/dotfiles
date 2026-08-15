vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

require("config.lazy")
require('lualine').setup()
require("nvim-tree").setup()
require("ibl").setup()
require("mason-lspconfig").setup()
require("bufferline").setup{}
require("noice").setup({
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
})
require("mason").setup {
  firewall = {
    enabled = true
  }
}

local builtin = require('telescope.builtin')
local cmp = require('cmp')
cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body) -- if using LuaSnip
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
  })
})

vim.keymap.set('n', 'c ', '<cmd>NvimTreeToggle<CR>', { desc = 'Toggle NvimTree' })
vim.keymap.set('n', 'cc', '<cmd>vert term<CR>', { desc = 'Open terminal' })
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
