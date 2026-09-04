vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
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

vim.keymap.set("v", "<C-c>", '"+y')
vim.keymap.set("v", "<C-x>", '"+d')
vim.keymap.set("i", "<C-v>", "<C-r>+")
vim.keymap.set("c", "<C-v>", "<C-r>+")
vim.keymap.set("n", "<C-v>", '"+p')

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

map("n", "<leader>on", "<cmd>ObsidianNew<cr>", { desc = "Create New Note" })
map("n", "<leader>oo", "<cmd>ObsidianQuickSwitch<cr>", { desc = "Quick Switch Note" })
map("n", "<leader>od", "<cmd>ObsidianToday<cr>", { desc = "Open Today's Daily Note" })
map("n", "<leader>os", "<cmd>ObsidianSearch<cr>", { desc = "Search Notes Text" })
map("n", "<leader>ob", "<cmd>ObsidianBacklinks<cr>", { desc = "Show Backlinks Panel" })
map("n", "<leader>ol", "<cmd>ObsidianLink<cr>", { desc = "Link Highlighted Text" })

local vault_path = vim.fn.expand("~/vaults/personal")

_G.is_in_vault = function(file_path)
  if not file_path or file_path == "" then return false end
  local abs_file = vim.fn.fnamemodify(file_path, ":p")
  local abs_vault = vim.fn.fnamemodify(vault_path, ":p")
  local abs_cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")

  return abs_file:find(abs_vault, 1, true) == 1 or abs_cwd:find(abs_vault, 1, true) == 1
end

_G.sync_obsidian_vault = function()
  if not _G.is_in_vault(vim.api.nvim_buf_get_name(0)) then
    return
  end

  local commit_msg = "auto-sync: " .. os.date("%Y-%m-%d %H:%M:%S")
  local cmd = string.format(
    "cd %s && git add -A . && if ! git diff-index --quiet HEAD; then git commit -m %s && git pull --rebase -X theirs --autostash origin main && git push origin main; fi",
    vim.fn.shellescape(vault_path),
    vim.fn.shellescape(commit_msg)
  )

  vim.fn.jobstart({ "bash", "-c", cmd }, { detach = true })
end

local function sync_vault_pull()
  if _G.is_in_vault(vim.fn.getcwd()) then
    local cmd = string.format("cd %s && git pull --rebase -X theirs --autostash origin main", vim.fn.shellescape(vault_path))
    vim.fn.jobstart({ "bash", "-c", cmd }, {
      detach = true,
      on_exit = function(_, code)
        if code == 0 then
          vim.schedule(function()
            vim.cmd("checktime")
          end)
        end
      end,
    })
  end
end

local vault_group = vim.api.nvim_create_augroup("ObsidianAutoSync", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
  group = vault_group,
  callback = sync_vault_pull,
})

vim.api.nvim_create_autocmd({ "BufWritePost", "VimLeavePre" }, {
  group = vault_group,
  callback = function()
    if _G.is_in_vault(vim.api.nvim_buf_get_name(0)) then
      _G.sync_obsidian_vault()
    end
  end,
})

local function show_ascii_graph()
  local current_file = vim.api.nvim_buf_get_name(0)
  if current_file == "" then return end

  local cmd = string.format("obsidian-ascii-graph %s", vim.fn.shellescape(current_file))
  local output = vim.fn.systemlist(cmd)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
  vim.bo[buf].filetype = "markdown"

  local width = 50
  local height = math.max(#output + 2, 5)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Note Graph ",
    title_pos = "center",
  }

  local win = vim.api.nvim_open_win(buf, true, opts)

  local map_opts = { buffer = buf, silent = true }
  vim.keymap.set("n", "q", "<cmd>close<CR>", map_opts)
  vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", map_opts)
end

vim.keymap.set("n", "<leader>og", show_ascii_graph, { desc = "Show ASCII Link Graph" })

vim.cmd("cnoreabbrev W w")
