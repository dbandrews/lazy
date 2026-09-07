-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

local opt = vim.opt
local g = vim.g

-- ╭──────────────────────────────────────────────────────────╮
-- │ Leaders                                                  │
-- ╰──────────────────────────────────────────────────────────╯
g.mapleader = " "
g.maplocalleader = "\\"

-- ╭──────────────────────────────────────────────────────────╮
-- │ Python toolchain                                         │
-- ╰──────────────────────────────────────────────────────────╯

-- basedpyright is the open-source successor to pyright and is the closest
-- thing to VS Code's Pylance (inlay hints, semantic tokens, better inference).
g.lazyvim_python_lsp = "basedpyright"
g.lazyvim_python_ruff = "ruff"

-- Dedicated venv used ONLY by Neovim's python provider (pynvim, jupyter_client,
-- jupytext, debugpy...). Keeping it separate from project venvs means molten &
-- friends keep working no matter which project venv is active.
local nvim_venv = vim.fn.expand("~/.venvs/nvim")
if vim.fn.executable(nvim_venv .. "/bin/python") == 1 then
  g.python3_host_prog = nvim_venv .. "/bin/python"
end

-- Providers we don't use -- skips a few subprocess probes at startup.
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0

-- ╭──────────────────────────────────────────────────────────╮
-- │ Molten (Jupyter kernel runner)                           │
-- ╰──────────────────────────────────────────────────────────╯
-- These have to be globals and have to be set before molten loads.
g.molten_auto_open_output = false -- don't steal focus; use <leader>jo
g.molten_output_virt_lines = true
g.molten_virt_text_output = true -- show output inline under the cell (VS Code-ish)
g.molten_virt_lines_off_by_1 = false -- correct for `# %%` cell markers
g.molten_wrap_output = true
g.molten_output_win_max_height = 20
g.molten_output_show_more = true
g.molten_use_border_highlights = true
g.molten_virt_text_max_lines = 24
g.molten_copy_output = true

-- Windows Terminal speaks neither the kitty nor the iTerm graphics protocol, so
-- images can't be drawn in the buffer. They're written to disk instead and
-- `:MoltenImagePopup` (<leader>jp) hands them to the Windows image viewer.
-- If you switch to WezTerm, set this to "wezterm" and images render inline.
g.molten_image_provider = "none"
if vim.fn.executable("wslview") == 1 then
  g.molten_open_cmd = "wslview" -- for :MoltenOpenInBrowser (plotly, HTML reprs)
end

-- Neovim's built-in filetype rule maps `*.ipynb` to json, which is right for the
-- raw file and wrong for us: jupytext replaces the buffer with the python
-- representation before we ever see it. Say python up front so that any later
-- filetype re-detection doesn't hand the buffer to jsonls.
vim.filetype.add({ extension = { ipynb = "python" } })

-- ╭──────────────────────────────────────────────────────────╮
-- │ Editor                                                   │
-- ╰──────────────────────────────────────────────────────────╯
opt.relativenumber = false -- VS Code shows absolute line numbers
opt.wrap = false
opt.scrolloff = 8
opt.confirm = true -- ask instead of failing on :q with unsaved changes
opt.splitkeep = "screen"
opt.cursorline = true
opt.termguicolors = true

-- Format on save (LazyVim reads this). Toggle per-buffer/globally with <leader>uf.
g.autoformat = true

-- Show the "inlay hints" VS Code/Pylance users expect.
g.lazyvim_inlay_hints = true
