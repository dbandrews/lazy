-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

local function augroup(name)
  return vim.api.nvim_create_augroup("drumm_" .. name, { clear = true })
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Python buffers                                                       │
-- ╰──────────────────────────────────────────────────────────────────────╯
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("python"),
  pattern = "python",
  callback = function()
    -- PEP 8 + a ruler where ruff's default line-length sits
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.colorcolumn = "88"

    -- Vim's python ftplugin turns on comment continuation, so opening a line
    -- under `# %%` (or any comment) hands you a `# ` you didn't ask for -- which
    -- silently comments out the first line of a new notebook cell. VS Code does
    -- not do this, so switch it off.
    vim.opt_local.formatoptions:remove({ "r", "o" })
  end,
})

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Jupyter notebooks (*.ipynb)                                          │
-- ╰──────────────────────────────────────────────────────────────────────╯
-- jupytext.nvim turns the notebook into a `# %%` python buffer on read and
-- converts it back on write. Molten runs the cells. These autocmds glue the two
-- together so that cell *outputs* survive the round trip, the way they do in
-- VS Code.

-- jupytext owns a `BufReadCmd` for *.ipynb, and a `BufReadCmd` *replaces* the
-- normal read -- so `BufReadPre`/`BufReadPost` never fire for notebooks. lazy.nvim
-- uses exactly those events to load nvim-lspconfig, gitsigns, and friends, which
-- is why a notebook would otherwise open with no LSP attached at all. Fire the
-- swallowed events by hand, once per buffer, then re-run FileType so the language
-- servers pick the buffer up.
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = augroup("ipynb_file_events"),
  pattern = "*.ipynb",
  callback = function(event)
    if vim.b[event.buf].ipynb_file_events then
      return
    end
    vim.b[event.buf].ipynb_file_events = true

    -- BufReadPost also re-runs filetype detection, so remember what jupytext
    -- decided (python for a python notebook, r for an R one, ...) and restore it.
    local ft = vim.bo[event.buf].filetype
    vim.api.nvim_exec_autocmds("BufReadPre", { buffer = event.buf })
    vim.api.nvim_exec_autocmds("BufReadPost", { buffer = event.buf })

    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(event.buf) then
        return
      end
      -- setting filetype fires FileType, which is what makes vim.lsp.enable()
      -- attach the servers; assign it even when unchanged
      vim.bo[event.buf].filetype = ft
    end)
  end,
})

-- Pick the kernel the notebook was authored with (falling back to the active
-- venv's name), start it, and pull existing outputs into the buffer.
local function init_molten_buffer(event)
  vim.schedule(function()
    local ok_kernels, kernels = pcall(vim.fn.MoltenAvailableKernels)
    if not ok_kernels or type(kernels) ~= "table" or #kernels == 0 then
      return
    end

    local kernel_name = nil

    -- 1. the kernel recorded in the notebook's metadata
    local ok, from_meta = pcall(function()
      local f = assert(io.open(event.file, "r"))
      local content = f:read("a")
      f:close()
      return vim.json.decode(content).metadata.kernelspec.name
    end)
    if ok and vim.tbl_contains(kernels, from_meta) then
      kernel_name = from_meta
    end

    -- 2. a kernel named after the active virtualenv
    if not kernel_name then
      local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
      if venv then
        local candidate = vim.fn.fnamemodify(venv, ":t")
        if vim.tbl_contains(kernels, candidate) then
          kernel_name = candidate
        end
      end
    end

    -- 3. plain old python3
    if not kernel_name and vim.tbl_contains(kernels, "python3") then
      kernel_name = "python3"
    end

    if kernel_name then
      vim.cmd(("MoltenInit %s"):format(kernel_name))
      pcall(vim.cmd, "MoltenImportOutput")
    end
  end)
end

vim.api.nvim_create_autocmd("BufAdd", {
  group = augroup("ipynb_molten"),
  pattern = "*.ipynb",
  callback = init_molten_buffer,
})

-- BufAdd doesn't fire for the file passed on the command line (`nvim nb.ipynb`)
vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup("ipynb_molten_enter"),
  pattern = "*.ipynb",
  callback = function(event)
    if vim.v.vim_did_enter ~= 1 then
      init_molten_buffer(event)
    end
  end,
})

-- `BufWriteCmd` replaces the write -- and with it `BufWritePre`, which is the
-- event LazyVim's format-on-save (and anything else that touches a buffer just
-- before it hits disk) hangs off. Replay it here, then fall through to jupytext's
-- own `BufWriteCmd`, which performs the real .ipynb conversion. This autocmd is
-- created at startup and jupytext's is created per buffer on read, so ours runs
-- first, which is what makes the ordering work.
vim.api.nvim_create_autocmd("BufWriteCmd", {
  group = augroup("ipynb_write_pre"),
  pattern = "*.ipynb",
  nested = true,
  callback = function(event)
    if not vim.b[event.buf].ipynb_in_write then
      vim.b[event.buf].ipynb_in_write = true
      pcall(vim.api.nvim_exec_autocmds, "BufWritePre", { buffer = event.buf })
      vim.b[event.buf].ipynb_in_write = false
    end

    -- Buffer-local `BufWriteCmd`s are jupytext's; if there is none (a brand new
    -- notebook that was never read) nothing else will write the file, so do the
    -- plain write Neovim would have done had we not intercepted it.
    if #vim.api.nvim_get_autocmds({ event = "BufWriteCmd", buffer = event.buf }) == 0 then
      vim.api.nvim_buf_call(event.buf, function()
        vim.cmd("noautocmd write")
      end)
    end
  end,
})

-- Write the outputs of everything you ran back into the .ipynb on save.
vim.api.nvim_create_autocmd("BufWritePost", {
  group = augroup("ipynb_export"),
  pattern = "*.ipynb",
  callback = function()
    local ok, status = pcall(require, "molten.status")
    if ok and status.initialized() == "Molten" then
      pcall(vim.cmd, "MoltenExportOutput!")
    end
  end,
})

-- Inline virtual-text output is great in a notebook and noisy in a plain script,
-- so flip it per filetype (molten needs both the global and the live option set).
local function molten_virt_text(enabled)
  local ok, status = pcall(require, "molten.status")
  if ok and status.initialized() == "Molten" then
    pcall(vim.fn.MoltenUpdateOption, "virt_text_output", enabled)
  else
    vim.g.molten_virt_text_output = enabled
  end
end

vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup("molten_virt_text"),
  pattern = { "*.py", "*.ipynb", "*.qmd", "*.md" },
  callback = function(event)
    if event.file:match("%.otter%.") then
      return
    end
    molten_virt_text(event.file:match("%.py$") == nil)
  end,
})

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ :NewNotebook path/name                                               │
-- ╰──────────────────────────────────────────────────────────────────────╯
-- jupytext needs a valid .ipynb on disk to convert, so an empty buffer isn't
-- enough -- write a minimal-but-valid notebook and open it.
local blank_notebook = {
  cells = {
    { cell_type = "code", execution_count = vim.NIL, metadata = vim.empty_dict(), outputs = {}, source = {} },
  },
  metadata = {
    kernelspec = { display_name = "Python 3", language = "python", name = "python3" },
    language_info = { file_extension = ".py", mimetype = "text/x-python", name = "python", version = "3" },
  },
  nbformat = 4,
  nbformat_minor = 5,
}

vim.api.nvim_create_user_command("NewNotebook", function(opts)
  local path = opts.args
  if not path:match("%.ipynb$") then
    path = path .. ".ipynb"
  end
  if vim.fn.filereadable(path) == 1 then
    vim.notify(path .. " already exists", vim.log.levels.WARN)
    return
  end
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local f, err = io.open(path, "w")
  if not f then
    vim.notify("Could not create notebook: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  f:write(vim.json.encode(blank_notebook))
  f:close()
  vim.cmd.edit(path)
end, { nargs = 1, complete = "file", desc = "Create and open a new Jupyter notebook" })
