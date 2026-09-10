vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true
vim.opt.conceallevel = 2

require("config.lazy")

local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "path" },
    {
      name = "buffer",
      option = {
        entry_filter = function(entry, ctx)
          return string.len(entry:get_insert_text()) < 30
        end,
      },
    },
  }),
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local opts = { buffer = event.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
  end,
})

local builtin = require("telescope.builtin")

vim.keymap.set("n", "c ", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })
vim.keymap.set("n", "cc", "<cmd>vert term<CR>", { desc = "Open terminal" })
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })

vim.keymap.set('v', '<C-c>', '"+y', { desc = 'Copy selection to system clipboard' })
vim.keymap.set('v', '<C-x>', '"+d', { desc = 'Cut selection to system clipboard' })
vim.keymap.set('v', '<C-v>', '"+p', { desc = 'Paste over selection from system clipboard' })

vim.keymap.set("n", "<leader>cx", function()
  local line = vim.api.nvim_get_current_line()
  if string.find(line, "%[ %]") then
    vim.cmd("s/\\[ \\]/\\[x\\]/")
  elseif string.find(line, "%[x%]") then
    vim.cmd("s/\\[x\\]/\\[ \\]/")
  end
  vim.cmd("nohlsearch")
end, { desc = "Toggle Checklist Item" })

local map = vim.keymap.set

vim.opt.clipboard = "unnamedplus"

vim.cmd("cnoreabbrev W w")
vim.o.shell = "fish"
