-- Cell running for `# %%` notebooks.
--
-- NotebookNavigator ships its own molten integration, but it evaluates
-- `[cell_start, cell_end + 1]`, which parks the cell's end extmark on the *next*
-- cell's `# %%` marker -- so the inline output renders under the following cell.
-- Molten's 4-argument `MoltenEvaluateRange(start, end, start_col, end_col)` lets
-- us end the range exactly on the cell's last non-blank line instead, which puts
-- the output directly beneath the code the way VS Code does.

local M = {}

local function nn()
  return require("notebook-navigator")
end

---Inner bounds of the cell under the cursor, ignoring trailing blank lines.
---@return integer from, integer to  (1-based, inclusive)
function M.cell_bounds()
  local spec = nn().miniai_spec("i")
  local from, to = spec.from.line, spec.to.line
  while to > from and vim.fn.getline(to):match("^%s*$") do
    to = to - 1
  end
  return from, to
end

---Send the cell under the cursor to the kernel.
---@return boolean ran
function M.run_cell()
  local from, to = M.cell_bounds()

  -- Nothing to send if the cell is blank or is only comments. This is what keeps
  -- jupytext's YAML front matter and `# %% [markdown]` prose out of the kernel.
  local has_code = false
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, from - 1, to, false)) do
    if not line:match("^%s*$") and not line:match("^%s*#") then
      has_code = true
      break
    end
  end
  if not has_code then
    return false
  end

  local ok = pcall(vim.fn.MoltenEvaluateRange, from, to, 1, #vim.fn.getline(to) + 1)
  if not ok then
    -- no kernel attached to this buffer yet
    vim.cmd("MoltenInit")
    return false
  end
  return true
end

---Run the cell and move to the next one, creating it if we're at the end.
function M.run_and_move()
  M.run_cell()
  if nn().move_cell("d") == "last" then
    nn().add_cell_below()
  end
end

---@param opts? { from_top?: boolean, to_bottom?: boolean }
local function run_sweep(opts)
  opts = opts or {}
  local win = vim.api.nvim_get_current_win()
  local saved = vim.api.nvim_win_get_cursor(win)
  local stop_at = opts.to_bottom and math.huge or saved[1]

  if opts.from_top then
    vim.api.nvim_win_set_cursor(win, { 1, 0 })
  end

  for _ = 1, 1000 do
    M.run_cell()
    if vim.api.nvim_win_get_cursor(win)[1] >= stop_at then
      break
    end
    if nn().move_cell("d") == "last" then
      break
    end
  end

  pcall(vim.api.nvim_win_set_cursor, win, saved)
end

function M.run_all()
  run_sweep({ from_top = true, to_bottom = true })
end

---Run every cell from the top of the file down to and including this one.
function M.run_above()
  run_sweep({ from_top = true })
end

---Run this cell and every cell below it.
function M.run_below()
  run_sweep({ to_bottom = true })
end

return M
