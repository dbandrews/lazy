-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--
-- This file adds a "VS Code muscle-memory" layer on top of the LazyVim defaults.
-- Every mapping here has a `<leader>` equivalent from LazyVim, so nothing breaks
-- if your terminal can't produce a given chord -- see the README for the table.
--
-- Deliberately NOT remapped, because they are core Vim motions:
--   <C-a> <C-f> <C-d> <C-u> <C-o> <C-i> <C-r> <C-v> <C-w> <C-e> <C-y>

local map = vim.keymap.set

-- ╭──────────────────────────────────────────────────────────╮
-- │ Files, search, palette                                   │
-- ╰──────────────────────────────────────────────────────────╯
-- Ctrl+P -- Go to File
map("n", "<C-p>", function()
  Snacks.picker.files({ cwd = LazyVim.root() })
end, { desc = "Go to File" })

-- Ctrl+Shift+P -- Command Palette (needs a terminal that sends CSI-u, e.g. WezTerm/kitty)
map("n", "<C-S-p>", function()
  Snacks.picker.commands()
end, { desc = "Command Palette" })

-- Ctrl+Shift+F -- Search across files
map("n", "<C-S-f>", function()
  Snacks.picker.grep({ cwd = LazyVim.root() })
end, { desc = "Search in Files" })

-- Ctrl+Shift+O -- Go to Symbol in file / Ctrl+T -- workspace symbols
map("n", "<C-S-o>", function()
  Snacks.picker.lsp_symbols()
end, { desc = "Go to Symbol" })

-- Ctrl+Shift+M -- Problems panel
map("n", "<C-S-m>", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Problems" })

-- ╭──────────────────────────────────────────────────────────╮
-- │ Sidebar / panel                                          │
-- ╰──────────────────────────────────────────────────────────╯
-- Ctrl+B / Ctrl+Shift+E -- toggle the Explorer
map("n", "<C-b>", "<cmd>Neotree toggle reveal<cr>", { desc = "Toggle Explorer" })
map("n", "<C-S-e>", "<cmd>Neotree focus reveal<cr>", { desc = "Focus Explorer" })

-- Ctrl+J -- toggle the bottom panel (terminal), like VS Code.
-- (LazyVim's default <C-/> is reclaimed below for "toggle comment".)
map({ "n", "t" }, "<C-j>", function()
  Snacks.terminal.focus(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })

-- ╭──────────────────────────────────────────────────────────╮
-- │ Editing                                                  │
-- ╰──────────────────────────────────────────────────────────╯
-- Ctrl+S -- save
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- Ctrl+/ -- toggle comment (most terminals send <C-_> for this chord)
for _, lhs in ipairs({ "<C-/>", "<C-_>" }) do
  map("n", lhs, "gcc", { remap = true, desc = "Toggle Comment" })
  map("x", lhs, "gc", { remap = true, desc = "Toggle Comment" })
  map("i", lhs, "<esc>gccgi", { remap = true, desc = "Toggle Comment" })
end

-- Alt+Up/Down -- move line(s); Alt+Shift+Up/Down -- duplicate line(s)
map("n", "<A-Up>", "<cmd>execute 'move .-2'<cr>==", { desc = "Move Line Up" })
map("n", "<A-Down>", "<cmd>execute 'move .+1'<cr>==", { desc = "Move Line Down" })
map("i", "<A-Up>", "<esc><cmd>execute 'move .-2'<cr>==gi", { desc = "Move Line Up" })
map("i", "<A-Down>", "<esc><cmd>execute 'move .+1'<cr>==gi", { desc = "Move Line Down" })
map("x", "<A-Up>", ":move '<-2<cr>gv=gv", { desc = "Move Lines Up" })
map("x", "<A-Down>", ":move '>+1<cr>gv=gv", { desc = "Move Lines Down" })
map("n", "<A-S-Up>", "<cmd>t .-1<cr>", { desc = "Duplicate Line Up" })
map("n", "<A-S-Down>", "<cmd>t .<cr>", { desc = "Duplicate Line Down" })
map("x", "<A-S-Down>", ":t '><cr>gv", { desc = "Duplicate Lines" })

-- Ctrl+Tab / Ctrl+Shift+Tab -- cycle buffers (LazyVim also gives you <S-h>/<S-l>)
map("n", "<C-Tab>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<C-S-Tab>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })

-- ╭──────────────────────────────────────────────────────────╮
-- │ Language features                                        │
-- ╰──────────────────────────────────────────────────────────╯
-- F12 -- Go to Definition, Shift+F12 -- Find All References
map("n", "<F12>", function()
  Snacks.picker.lsp_definitions()
end, { desc = "Go to Definition" })
map("n", "<S-F12>", function()
  Snacks.picker.lsp_references()
end, { desc = "Find All References" })

-- F2 -- Rename Symbol
map("n", "<F2>", function()
  if LazyVim.has("inc-rename.nvim") then
    return ":IncRename " .. vim.fn.expand("<cword>")
  end
  vim.lsp.buf.rename()
end, { expr = true, desc = "Rename Symbol" })

-- Shift+Alt+F -- Format Document
map({ "n", "v" }, "<S-A-f>", function()
  LazyVim.format({ force = true })
end, { desc = "Format Document" })

-- Ctrl+. -- Quick Fix / code actions
map({ "n", "v" }, "<C-.>", vim.lsp.buf.code_action, { desc = "Code Action" })

-- ╭──────────────────────────────────────────────────────────╮
-- │ Debugging (F5/F9/F10/F11 exactly like VS Code)           │
-- ╰──────────────────────────────────────────────────────────╯
map("n", "<F5>", function()
  require("dap").continue()
end, { desc = "Debug: Start/Continue" })
map("n", "<S-F5>", function()
  require("dap").terminate()
end, { desc = "Debug: Stop" })
map("n", "<C-S-F5>", function()
  require("dap").restart()
end, { desc = "Debug: Restart" })
map("n", "<F9>", function()
  require("dap").toggle_breakpoint()
end, { desc = "Debug: Toggle Breakpoint" })
map("n", "<S-F9>", function()
  require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug: Conditional Breakpoint" })
map("n", "<F10>", function()
  require("dap").step_over()
end, { desc = "Debug: Step Over" })
map("n", "<F11>", function()
  require("dap").step_into()
end, { desc = "Debug: Step Into" })
map("n", "<S-F11>", function()
  require("dap").step_out()
end, { desc = "Debug: Step Out" })
map("n", "<F6>", function()
  require("dapui").toggle()
end, { desc = "Debug: Toggle UI" })
