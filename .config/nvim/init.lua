vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

require("config.lazy")
require('lualine').setup()
require("nvim-tree").setup()
require("ibl").setup()


require("mason").setup({
  firewall = {
    enabled = true
  }
})
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

local builtin = require('telescope.builtin')
local cmp = require('cmp')

cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body) 
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { 
      name = 'buffer',
      option = {
        get_bufnrs = function()
          return vim.api.nvim_list_bufs()
        end
      }
    },
    { name = 'path' },
  })
})

vim.cmd([[filetype plugin indent on]])

vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
    end,
})

vim.opt.conceallevel = 2

vim.keymap.set("n", "<leader>cx", function()
    local line = vim.api.nvim_get_current_line()
    if string.find(line, "%[ %]") then
        vim.cmd("s/\\[ \\]/\\[x\\]/")
    elseif string.find(line, "%[x%]") then
        vim.cmd("s/\\[x\\]/\\[ \\]/")
    end
    vim.cmd("nohlsearch") 
end, { desc = "Toggle Checklist Item" })

-- Ensure unnamedplus is enabled
vim.opt.clipboard = "unnamedplus"

-- Visual mode: Ctrl+C to copy, Ctrl+X to cut
vim.keymap.set("v", "<C-c>", '"+y')
vim.keymap.set("v", "<C-x>", '"+d')

-- Insert and Command modes: Ctrl+V to paste
vim.keymap.set("i", "<C-v>", '<C-r>+')
vim.keymap.set("c", "<C-v>", '<C-r>+')

-- Normal mode: Ctrl+V to paste (overrides Visual Block mode)
vim.keymap.set("n", "<C-v>", '"+p')

vim.keymap.set("n", "gd", "<cmd>ObsidianFollowLink<cr>", { desc = "Go to Note Link" })
vim.keymap.set("n", "<leader>on", "<cmd>ObsidianNew<cr>", { desc = "Create New Note" })
vim.keymap.set("n", "<leader>os", "<cmd>ObsidianSearch<cr>", { desc = "Search Notes text" })
vim.keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<cr>", { desc = "Show Backlinks panel" })
vim.keymap.set('n', 'c ', '<cmd>NvimTreeToggle<CR>', { desc = 'Toggle NvimTree' })
vim.keymap.set('n', 'cc', '<cmd>vert term<CR>', { desc = 'Open terminal' })
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
