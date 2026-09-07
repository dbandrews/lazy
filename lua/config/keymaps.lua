-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--
-- The "VS Code muscle memory" layer is defined as data in lua/util/vscode_keys.lua
-- so that the cheatsheet is generated from the same table that creates the
-- mappings. Edit that file to change a binding.
--
-- Finding a shortcut:
--   <leader>k   this config's cheatsheet, grouped, with the VS Code equivalent
--   <leader>sk  fuzzy search across every keymap Neovim knows about
--   <leader>?   which-key, for the current buffer
--   <leader>    (just wait) which-key shows what can follow it

local vscode_keys = require("util.vscode_keys")

vscode_keys.setup()

vim.api.nvim_create_user_command("Cheatsheet", vscode_keys.show, { desc = "Keyboard shortcut cheatsheet" })

vim.keymap.set("n", "<leader>k", vscode_keys.show, { desc = "Keyboard Shortcuts (cheatsheet)" })
-- VS Code opens its own keyboard shortcut list on Ctrl+K Ctrl+S
vim.keymap.set("n", "<C-k><C-s>", vscode_keys.show, { desc = "Keyboard Shortcuts (cheatsheet)" })
