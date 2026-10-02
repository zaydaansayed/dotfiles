-- C/C++ workflow: indent, build/run, debugging.
-- Loaded from init.lua. Assumes clangd (LSP), conform (format),
-- nvim-dap + codelldb/cppdbg (debug) from plugins.lua.

local M = {}

-- 4-space indents, expand tabs, smart C indent
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "h", "hpp", "cmake" },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
    vim.opt_local.cindent = true
  end,
})

-- Build helpers -------------------------------------------------------
local function cpp_current_file()
  return vim.fn.expand("%:p")
end

local function cpp_output_basename()
  return vim.fn.expand("%:p:r")
end

-- Compile single file with g++. Uses C++23, warnings, debug info.
function M.compile_current()
  local src = cpp_current_file()
  if src == "" then
    vim.notify("No file to compile", vim.log.levels.WARN)
    return
  end
  local out = cpp_output_basename()
  local cmd = string.format(
    "g++ -std=c++23 -Wall -Wextra -g '%s' -o '%s' && echo BUILD OK: %s",
    src, out, out
  )
  vim.cmd("split | terminal " .. cmd)
end

-- Compile + run single file.
function M.run_current()
  local src = cpp_current_file()
  if src == "" then
    vim.notify("No file to run", vim.log.levels.WARN)
    return
  end
  local out = cpp_output_basename()
  local cmd = string.format(
    "g++ -std=c++23 -Wall -Wextra -g '%s' -o '%s' && '%s'",
    src, out, out
  )
  vim.cmd("split | terminal " .. cmd)
end

-- CMake project: configure + build in ./build (Ninja or Make fallback).
function M.cmake_build()
  local cmds = {
    "cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
    "cmake --build build -j$(nproc)",
  }
  vim.cmd("split | terminal " .. table.concat(cmds, " && "))
end

vim.api.nvim_create_user_command("CppCompile", M.compile_current, { desc = "g++ compile current file" })
vim.api.nvim_create_user_command("CppRun", M.run_current, { desc = "g++ compile & run current file" })
vim.api.nvim_create_user_command("CMakeBuild", M.cmake_build, { desc = "cmake configure & build ./build" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "h", "hpp" },
  callback = function(ev)
    local opts = { buffer = ev.buf, silent = true }
    vim.keymap.set("n", "<leader>cc", M.compile_current,
      vim.tbl_extend("force", opts, { desc = "C++: compile current file" }))
    vim.keymap.set("n", "<leader>cr", M.run_current,
      vim.tbl_extend("force", opts, { desc = "C++: compile & run current file" }))
    vim.keymap.set("n", "<leader>cb", M.cmake_build,
      vim.tbl_extend("force", opts, { desc = "C++: cmake build ./build" }))
  end,
})

-- DAP -----------------------------------------------------------------
local function setup_dap()
  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then return end

  -- Primary: system gdb via native DAP (gdb 14+, you have 17).
  -- No Mason download needed.
  dap.adapters.gdb = {
    type = "executable",
    command = "/usr/bin/gdb",
    args = { "-i", "dap" },
  }
  local gdb_launch = {
    name = "Launch current file (gdb)",
    type = "gdb",
    request = "launch",
    program = function()
      return vim.fn.input("Executable: ", cpp_output_basename(), "file")
    end,
    cwd = "${workspaceFolder}",
    stopAtBeginningOfMainSubprogram = false,
  }
  dap.configurations.cpp = { gdb_launch }
  dap.configurations.c = { gdb_launch }

  -- Optional: codelldb from Mason, if ever installed.
  local codelldb = vim.fn.stdpath("data") .. "/mason/bin/codelldb"
  if vim.fn.executable(codelldb) == 1 then
    dap.adapters.codelldb = {
      type = "server",
      port = "${port}",
      executable = { command = codelldb, args = { "--port", "${port}" } },
    }
    table.insert(dap.configurations.cpp, {
      name = "Launch current file (codelldb)",
      type = "codelldb",
      request = "launch",
      program = function()
        return vim.fn.input("Executable: ", cpp_output_basename(), "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
    })
  end

  -- Optional: gdb via cpptools (cppdbg), if ever installed via Mason.
  local opendebug = vim.fn.stdpath("data") .. "/mason/bin/OpenDebugAD7"
  if vim.fn.executable(opendebug) == 1 then
    dap.adapters.cppdbg = {
      id = "cppdbg",
      type = "executable",
      command = opendebug,
    }
    table.insert(dap.configurations.cpp, {
      name = "Launch current file (cppdbg/gdb)",
      type = "cppdbg",
      request = "launch",
      program = function()
        return vim.fn.input("Executable: ", cpp_output_basename(), "file")
      end,
      cwd = "${workspaceFolder}",
      stopAtEntry = false,
      MIMode = "gdb",
      miDebuggerPath = "/usr/bin/gdb",
      setupCommands = {
        { text = "-enable-pretty-printing", ignoreFailures = true },
      },
    })
  end
end

setup_dap()

-- DAP keymaps (global, mnemonic: d=debug)
vim.keymap.set("n", "<leader>db", function() require("dap").toggle_breakpoint() end, { desc = "DAP: toggle breakpoint" })
vim.keymap.set("n", "<leader>dc", function() require("dap").continue() end, { desc = "DAP: continue" })
vim.keymap.set("n", "<leader>di", function() require("dap").step_into() end, { desc = "DAP: step into" })
vim.keymap.set("n", "<leader>do", function() require("dap").step_over() end, { desc = "DAP: step over" })
vim.keymap.set("n", "<leader>dO", function() require("dap").step_out() end, { desc = "DAP: step out" })
vim.keymap.set("n", "<leader>dr", function() require("dap").repl.open() end, { desc = "DAP: open REPL" })
vim.keymap.set("n", "<leader>du", function()
  local ok, dapui = pcall(require, "dapui")
  if ok then dapui.toggle() end
end, { desc = "DAP: toggle UI" })
vim.keymap.set("n", "<leader>dt", function() require("dap").terminate() end, { desc = "DAP: terminate" })

return M
