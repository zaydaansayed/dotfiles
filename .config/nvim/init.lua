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
  callback = function()
    pcall(vim.treesitter.start)
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

-- Theme is optional: default_dark links no theme.lua (stock nvim look),
-- night_sky links its own. Missing module = defaults, no error.
local theme_ok, theme = pcall(require, "config.theme")
if theme_ok then theme.setup() end

-- Re-apply the linked theme without restarting.
-- eww application.sh swaps the theme.lua file on disk, but a running
-- nvim keeps the old module + highlights cached, so run :ThemeReload
-- (or restart nvim) after switching themes.
vim.api.nvim_create_user_command("ThemeReload", function()
  package.loaded["config.theme"] = nil
  local ok, t = pcall(require, "config.theme")
  if not ok then
    vim.notify("theme reload failed: " .. tostring(t), vim.log.levels.ERROR)
    return
  end
  t.setup()
  local ok_l, lualine = pcall(require, "lualine")
  if ok_l then lualine.setup(t.lualine_opts()) end
  local ok_b, bufferline = pcall(require, "bufferline")
  if ok_b then bufferline.setup(t.bufferline_opts()) end
  local ok_n, notify = pcall(require, "notify")
  if ok_n then notify.setup(t.notify_opts()) end
end, { desc = "Reload linked eww theme without restarting" })
