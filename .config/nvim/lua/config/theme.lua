-- eww night_sky palette (eww/scss/colors.scss)
-- accent_1 #E07D68 salmon / accent_2 #549D9D teal / accent_3 #E99AFF pink
-- accent_5 #A358D1 purple / $l4 #777777 muted / $border #090409
local M = {}

M.palette = {
  bg      = "#090409",
  surface = "#1B1428", -- cursorline / selections
  surface2 = "#2A2138", -- visual / pmenu-sel
  float   = "#151020", -- solid popup background
  fg      = "#FFFFFF", -- eww primary text
  muted   = "#777777", -- eww $l4 (comments, borders)
  violet  = "#A358D1", -- eww accent_5 (keywords)
  peach   = "#E07D68", -- eww accent_1 (functions)
  pink    = "#E99AFF", -- eww $on (types)
  teal    = "#549D9D", -- eww accent_2 (strings)
  orange  = "#FFB07C", -- constants / warnings
  brick   = "#C26B59", -- dark salmon (errors)
  brown   = "#88594B", -- eww accent_4 (sparing)
}

function M.setup()
  local p = M.palette
  local hl = vim.api.nvim_set_hl

  -- Editor (Normal stays transparent so kitty blur shows through)
  hl(0, "Normal", { bg = "none", fg = p.fg })
  hl(0, "NormalFloat", { bg = p.float, fg = p.fg })
  hl(0, "FloatBorder", { bg = p.float, fg = p.violet })
  hl(0, "CursorLine", { bg = p.surface })
  hl(0, "CursorLineNr", { fg = p.peach, bold = true })
  hl(0, "LineNr", { fg = p.muted })
  hl(0, "SignColumn", { bg = "none" })
  hl(0, "Visual", { bg = p.surface2 })
  hl(0, "Search", { bg = p.orange, fg = p.bg })
  hl(0, "IncSearch", { bg = p.peach, fg = p.bg })
  hl(0, "CurSearch", { bg = p.peach, fg = p.bg })
  hl(0, "Pmenu", { bg = p.float, fg = p.fg })
  hl(0, "PmenuSel", { bg = p.surface2, fg = p.peach, bold = true })
  hl(0, "PmenuSbar", { bg = p.surface })
  hl(0, "PmenuThumb", { bg = p.muted })
  hl(0, "WinSeparator", { fg = p.muted })
  hl(0, "StatusLine", { bg = "none", fg = p.fg })
  hl(0, "StatusLineNC", { bg = "none", fg = p.muted })
  hl(0, "Folded", { bg = p.surface, fg = p.muted })
  hl(0, "MatchParen", { fg = p.violet, bold = true, underline = true })
  hl(0, "NonText", { fg = p.muted })
  hl(0, "EndOfBuffer", { fg = p.muted })
  hl(0, "Directory", { fg = p.teal })
  hl(0, "Title", { fg = p.peach, bold = true })
  hl(0, "Question", { fg = p.teal })
  hl(0, "MoreMsg", { fg = p.teal })
  hl(0, "ModeMsg", { fg = p.muted })
  hl(0, "ErrorMsg", { fg = p.brick })
  hl(0, "WarningMsg", { fg = p.orange })
  hl(0, "Conceal", { fg = p.brown })
  hl(0, "SpecialKey", { fg = p.brown })

  -- Classic syntax
  hl(0, "Comment", { fg = p.muted, italic = true })
  hl(0, "Constant", { fg = p.orange })
  hl(0, "String", { fg = p.teal })
  hl(0, "Character", { fg = p.teal })
  hl(0, "Number", { fg = p.orange })
  hl(0, "Boolean", { fg = p.orange })
  hl(0, "Identifier", { fg = p.fg })
  hl(0, "Function", { fg = p.peach })
  hl(0, "Statement", { fg = p.violet })
  hl(0, "Keyword", { fg = p.violet })
  hl(0, "Conditional", { fg = p.violet })
  hl(0, "Repeat", { fg = p.violet })
  hl(0, "Operator", { fg = p.fg })
  hl(0, "PreProc", { fg = p.pink })
  hl(0, "Type", { fg = p.pink })
  hl(0, "Special", { fg = p.orange })
  hl(0, "Todo", { fg = p.brick, bold = true })
  hl(0, "Underlined", { fg = p.pink, underline = true })
  hl(0, "Error", { fg = p.brick })

  -- Treesitter
  hl(0, "@variable", { fg = p.fg })
  hl(0, "@variable.parameter", { fg = p.orange, italic = true })
  hl(0, "@function", { fg = p.peach })
  hl(0, "@function.call", { fg = p.peach })
  hl(0, "@method", { fg = p.peach })
  hl(0, "@method.call", { fg = p.peach })
  hl(0, "@keyword", { fg = p.violet })
  hl(0, "@keyword.function", { fg = p.violet })
  hl(0, "@keyword.return", { fg = p.violet })
  hl(0, "@string", { fg = p.teal })
  hl(0, "@number", { fg = p.orange })
  hl(0, "@boolean", { fg = p.orange })
  hl(0, "@constant", { fg = p.orange })
  hl(0, "@type", { fg = p.pink })
  hl(0, "@property", { fg = p.pink })
  hl(0, "@field", { fg = p.pink })
  hl(0, "@operator", { fg = p.fg })
  hl(0, "@punctuation", { fg = p.muted })
  hl(0, "@comment", { fg = p.muted, italic = true })
  hl(0, "@constructor", { fg = p.violet })
  hl(0, "@tag", { fg = p.violet })
  hl(0, "@attribute", { fg = p.orange })

  -- Diagnostics / LSP
  hl(0, "DiagnosticError", { fg = p.brick })
  hl(0, "DiagnosticWarn", { fg = p.orange })
  hl(0, "DiagnosticInfo", { fg = p.pink })
  hl(0, "DiagnosticHint", { fg = p.teal })
  hl(0, "DiagnosticUnderlineError", { sp = p.brick, undercurl = true })
  hl(0, "DiagnosticUnderlineWarn", { sp = p.orange, undercurl = true })
  hl(0, "DiagnosticUnderlineInfo", { sp = p.pink, undercurl = true })
  hl(0, "DiagnosticUnderlineHint", { sp = p.teal, undercurl = true })
  hl(0, "DiagnosticSignError", { fg = p.brick })
  hl(0, "DiagnosticSignWarn", { fg = p.orange })
  hl(0, "DiagnosticSignInfo", { fg = p.pink })
  hl(0, "DiagnosticSignHint", { fg = p.teal })
  hl(0, "LspReferenceRead", { bg = p.surface })
  hl(0, "LspReferenceWrite", { bg = p.surface })
  hl(0, "LspReferenceText", { bg = p.surface })

  -- Diff
  hl(0, "DiffAdd", { bg = "#12211D", fg = p.teal })
  hl(0, "DiffChange", { bg = "#221A2E", fg = p.pink })
  hl(0, "DiffDelete", { bg = "#251312", fg = p.brick })
  hl(0, "DiffText", { bg = "#2A2138", fg = p.orange })

  -- Gitsigns
  hl(0, "GitSignsAdd", { fg = p.teal })
  hl(0, "GitSignsChange", { fg = p.pink })
  hl(0, "GitSignsDelete", { fg = p.brick })
  hl(0, "GitSignsCurrentLineBlame", { fg = p.muted, italic = true })

  -- NvimTree
  hl(0, "NvimTreeNormal", { bg = "none", fg = p.fg })
  hl(0, "NvimTreeWinSeparator", { fg = p.muted })
  hl(0, "NvimTreeFolderIcon", { fg = p.pink })
  hl(0, "NvimTreeFolderName", { fg = p.pink })
  hl(0, "NvimTreeOpenedFolderName", { fg = p.peach })
  hl(0, "NvimTreeRootFolder", { fg = p.violet, bold = true })
  hl(0, "NvimTreeGitDirty", { fg = p.orange })
  hl(0, "NvimTreeGitNew", { fg = p.teal })
  hl(0, "NvimTreeGitDeleted", { fg = p.brick })
  hl(0, "NvimTreeIndentMarker", { fg = p.muted })

  -- Telescope
  hl(0, "TelescopeNormal", { bg = p.float, fg = p.fg })
  hl(0, "TelescopeBorder", { bg = p.float, fg = p.violet })
  hl(0, "TelescopePromptBorder", { bg = p.float, fg = p.peach })
  hl(0, "TelescopeResultsBorder", { bg = p.float, fg = p.violet })
  hl(0, "TelescopePreviewBorder", { bg = p.float, fg = p.violet })
  hl(0, "TelescopeSelection", { bg = p.surface2, fg = p.peach })
  hl(0, "TelescopeMatching", { fg = p.teal, bold = true })
  hl(0, "TelescopePromptPrefix", { fg = p.peach })

  -- Cmp kinds
  hl(0, "CmpItemAbbrMatch", { fg = p.teal, bold = true })
  hl(0, "CmpItemAbbrMatchFuzzy", { fg = p.teal, bold = true })
  hl(0, "CmpItemKindFunction", { fg = p.peach })
  hl(0, "CmpItemKindMethod", { fg = p.peach })
  hl(0, "CmpItemKindVariable", { fg = p.pink })
  hl(0, "CmpItemKindKeyword", { fg = p.violet })
  hl(0, "CmpItemKindText", { fg = p.fg })

  -- indent-blankline
  hl(0, "IblIndent", { fg = p.muted })
  hl(0, "IblScope", { fg = p.violet })

  -- alpha dashboard
  hl(0, "AlphaHeader", { fg = p.peach })
  hl(0, "AlphaButtons", { fg = p.violet })
  hl(0, "AlphaShortcut", { fg = p.teal })
  hl(0, "AlphaFooter", { fg = p.muted, italic = true })

  -- notify (needs a solid bg group since Normal is transparent)
  hl(0, "NotifyBackground", { bg = p.float })
  hl(0, "NotifyERRORIcon", { fg = p.brick })
  hl(0, "NotifyERRORTitle", { fg = p.brick })
  hl(0, "NotifyWARNIcon", { fg = p.orange })
  hl(0, "NotifyWARNTitle", { fg = p.orange })
  hl(0, "NotifyINFOIcon", { fg = p.pink })
  hl(0, "NotifyINFOTitle", { fg = p.pink })
end

return M
