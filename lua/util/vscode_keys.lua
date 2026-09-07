-- The VS Code keymap layer, as data.
--
-- Keeping it in a table rather than a pile of `vim.keymap.set` calls means the
-- cheatsheet (`<leader>k`) is rendered from the same source that creates the
-- mappings, so it cannot drift out of date.
--
-- Each entry:
--   lhs     string or list of strings (a list maps several chords to one action)
--   rhs     string or function
--   desc    shown by which-key, `<leader>sk` and the cheatsheet
--   vscode  the equivalent VS Code chord, for the cheatsheet's first column
--   mode    defaults to "n"
--   also    a `<leader>` mapping that does the same thing and always works,
--           even in a terminal that cannot encode `lhs`
--   opts    extra options passed through to `vim.keymap.set`

local M = {}

---@type { title: string, keys: table[] }[]
M.groups = {
  {
    title = "Files & search",
    keys = {
      {
        vscode = "Ctrl+P",
        lhs = "<C-p>",
        desc = "Go to File",
        also = "<leader>ff",
        rhs = function()
          Snacks.picker.files({ cwd = LazyVim.root() })
        end,
      },
      {
        vscode = "Ctrl+Shift+P",
        lhs = "<C-S-p>",
        desc = "Command Palette",
        also = "<leader>:",
        rhs = function()
          Snacks.picker.commands()
        end,
      },
      {
        vscode = "Ctrl+Shift+F",
        lhs = "<C-S-f>",
        desc = "Search in Files",
        also = "<leader>/",
        rhs = function()
          Snacks.picker.grep({ cwd = LazyVim.root() })
        end,
      },
      {
        vscode = "Ctrl+Shift+O",
        lhs = "<C-S-o>",
        desc = "Go to Symbol",
        also = "<leader>ss",
        rhs = function()
          Snacks.picker.lsp_symbols()
        end,
      },
      {
        vscode = "Ctrl+Tab",
        lhs = "<C-Tab>",
        desc = "Next Buffer",
        also = "<S-l>",
        rhs = "<cmd>bnext<cr>",
      },
      {
        vscode = "Ctrl+Shift+Tab",
        lhs = "<C-S-Tab>",
        desc = "Prev Buffer",
        also = "<S-h>",
        rhs = "<cmd>bprevious<cr>",
      },
    },
  },

  {
    title = "Sidebar & panels",
    keys = {
      {
        vscode = "Ctrl+B",
        lhs = "<C-b>",
        desc = "Toggle Explorer",
        also = "<leader>e",
        rhs = "<cmd>Neotree toggle reveal<cr>",
      },
      {
        vscode = "Ctrl+Shift+E",
        lhs = "<C-S-e>",
        desc = "Focus Explorer",
        also = "<leader>e",
        rhs = "<cmd>Neotree focus reveal<cr>",
      },
      {
        vscode = "Ctrl+J",
        lhs = "<C-j>",
        desc = "Terminal (Root Dir)",
        also = "<leader>ft",
        mode = { "n", "t" },
        rhs = function()
          Snacks.terminal.focus(nil, { cwd = LazyVim.root() })
        end,
      },
      {
        vscode = "Ctrl+Shift+M",
        lhs = "<C-S-m>",
        desc = "Problems",
        also = "<leader>xx",
        rhs = "<cmd>Trouble diagnostics toggle<cr>",
      },
    },
  },

  {
    title = "Editing",
    keys = {
      {
        vscode = "Ctrl+S",
        lhs = "<C-s>",
        desc = "Save File",
        also = ":w",
        mode = { "i", "x", "n", "s" },
        rhs = "<cmd>w<cr><esc>",
      },
      -- most terminals send <C-_> for Ctrl+/
      {
        vscode = "Ctrl+/",
        lhs = { "<C-/>", "<C-_>" },
        desc = "Toggle Comment",
        also = "gcc",
        rhs = "gcc",
        opts = { remap = true },
      },
      {
        lhs = { "<C-/>", "<C-_>" },
        desc = "Toggle Comment",
        mode = "x",
        rhs = "gc",
        opts = { remap = true },
        hidden = true,
      },
      {
        lhs = { "<C-/>", "<C-_>" },
        desc = "Toggle Comment",
        mode = "i",
        rhs = "<esc>gccgi",
        opts = { remap = true },
        hidden = true,
      },
      {
        vscode = "Alt+Up",
        lhs = "<A-Up>",
        desc = "Move Line Up",
        rhs = "<cmd>execute 'move .-2'<cr>==",
      },
      {
        vscode = "Alt+Down",
        lhs = "<A-Down>",
        desc = "Move Line Down",
        rhs = "<cmd>execute 'move .+1'<cr>==",
      },
      {
        lhs = "<A-Up>",
        desc = "Move Line Up",
        mode = "i",
        rhs = "<esc><cmd>execute 'move .-2'<cr>==gi",
        hidden = true,
      },
      {
        lhs = "<A-Down>",
        desc = "Move Line Down",
        mode = "i",
        rhs = "<esc><cmd>execute 'move .+1'<cr>==gi",
        hidden = true,
      },
      { lhs = "<A-Up>", desc = "Move Lines Up", mode = "x", rhs = ":move '<-2<cr>gv=gv", hidden = true },
      { lhs = "<A-Down>", desc = "Move Lines Down", mode = "x", rhs = ":move '>+1<cr>gv=gv", hidden = true },
      {
        vscode = "Alt+Shift+Down",
        lhs = "<A-S-Down>",
        desc = "Duplicate Line",
        rhs = "<cmd>t .<cr>",
      },
      {
        vscode = "Alt+Shift+Up",
        lhs = "<A-S-Up>",
        desc = "Duplicate Line Up",
        rhs = "<cmd>t .-1<cr>",
      },
      { lhs = "<A-S-Down>", desc = "Duplicate Lines", mode = "x", rhs = ":t '><cr>gv", hidden = true },
    },
  },

  {
    title = "Language features",
    keys = {
      {
        vscode = "F12",
        lhs = "<F12>",
        desc = "Go to Definition",
        also = "gd",
        rhs = function()
          Snacks.picker.lsp_definitions()
        end,
      },
      {
        vscode = "Shift+F12",
        lhs = "<S-F12>",
        desc = "Find All References",
        also = "gr",
        rhs = function()
          Snacks.picker.lsp_references()
        end,
      },
      {
        vscode = "F2",
        lhs = "<F2>",
        desc = "Rename Symbol",
        also = "<leader>cr",
        opts = { expr = true },
        rhs = function()
          if LazyVim.has("inc-rename.nvim") then
            return ":IncRename " .. vim.fn.expand("<cword>")
          end
          vim.lsp.buf.rename()
        end,
      },
      {
        vscode = "Shift+Alt+F",
        lhs = "<S-A-f>",
        desc = "Format Document",
        also = "<leader>cf",
        mode = { "n", "v" },
        rhs = function()
          LazyVim.format({ force = true })
        end,
      },
      {
        vscode = "Ctrl+.",
        lhs = "<C-.>",
        desc = "Code Action",
        also = "<leader>ca",
        mode = { "n", "v" },
        rhs = vim.lsp.buf.code_action,
      },
    },
  },

  {
    title = "Run & debug",
    keys = {
      {
        vscode = "F5",
        lhs = "<F5>",
        desc = "Debug: Start/Continue",
        also = "<leader>dc",
        rhs = function()
          require("dap").continue()
        end,
      },
      {
        vscode = "Shift+F5",
        lhs = "<S-F5>",
        desc = "Debug: Stop",
        also = "<leader>dt",
        rhs = function()
          require("dap").terminate()
        end,
      },
      {
        vscode = "Ctrl+Shift+F5",
        lhs = "<C-S-F5>",
        desc = "Debug: Restart",
        rhs = function()
          require("dap").restart()
        end,
      },
      {
        vscode = "F9",
        lhs = "<F9>",
        desc = "Debug: Toggle Breakpoint",
        also = "<leader>db",
        rhs = function()
          require("dap").toggle_breakpoint()
        end,
      },
      {
        vscode = "Shift+F9",
        lhs = "<S-F9>",
        desc = "Debug: Conditional Breakpoint",
        also = "<leader>dB",
        rhs = function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
      },
      {
        vscode = "F10",
        lhs = "<F10>",
        desc = "Debug: Step Over",
        also = "<leader>dO",
        rhs = function()
          require("dap").step_over()
        end,
      },
      {
        vscode = "F11",
        lhs = "<F11>",
        desc = "Debug: Step Into",
        also = "<leader>di",
        rhs = function()
          require("dap").step_into()
        end,
      },
      {
        vscode = "Shift+F11",
        lhs = "<S-F11>",
        desc = "Debug: Step Out",
        also = "<leader>do",
        rhs = function()
          require("dap").step_out()
        end,
      },
      {
        lhs = "<F6>",
        desc = "Debug: Toggle UI",
        also = "<leader>du",
        rhs = function()
          require("dapui").toggle()
        end,
      },
    },
  },
}

--- Create every mapping in `M.groups`.
function M.setup()
  for _, group in ipairs(M.groups) do
    for _, key in ipairs(group.keys) do
      local lhs = type(key.lhs) == "table" and key.lhs or { key.lhs }
      for _, l in ipairs(lhs) do
        local opts = vim.tbl_extend("force", { desc = key.desc }, key.opts or {})
        vim.keymap.set(key.mode or "n", l, key.rhs, opts)
      end
    end
  end
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Cheatsheet                                                          │
-- ╰──────────────────────────────────────────────────────────────────────╯

---Every mapping whose lhs starts with `prefix`, newest description wins.
---Used for the `<leader>`-based groups, which are defined by plugin specs
---rather than here, so the cheatsheet stays truthful without duplicating them.
---@param prefix string
local function mappings_under(prefix)
  local out = {}
  for _, mode in ipairs({ "n", "x" }) do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      local lhs = vim.fn.keytrans(vim.keycode(map.lhs))
      if vim.startswith(lhs, prefix) and map.desc and map.desc ~= "which_key_ignore" then
        out[lhs] = out[lhs] or { lhs = lhs, desc = map.desc, mode = mode }
      end
    end
  end
  return vim.tbl_values(out)
end

local function pretty(lhs)
  return (lhs:gsub("^<Space>", "<leader>"))
end

local function render()
  local lines = {
    "# Keyboard shortcuts",
    "",
    "Searchable list of *everything*: `<leader>sk`. This buffer: `/` to search, `q` to close.",
    "",
  }

  for _, group in ipairs(M.groups) do
    lines[#lines + 1] = "## " .. group.title
    lines[#lines + 1] = ""
    lines[#lines + 1] = "| VS Code | Key | Action | Always works |"
    lines[#lines + 1] = "| --- | --- | --- | --- |"
    for _, key in ipairs(group.keys) do
      if not key.hidden then
        local lhs = type(key.lhs) == "table" and key.lhs[1] or key.lhs
        lines[#lines + 1] = ("| %s | `%s` | %s | %s |"):format(
          key.vscode or "",
          lhs,
          key.desc,
          key.also and ("`" .. key.also .. "`") or ""
        )
      end
    end
    lines[#lines + 1] = ""
  end

  local jupyter = mappings_under("<Space>j")
  if #jupyter > 0 then
    table.sort(jupyter, function(a, b)
      return a.lhs < b.lhs
    end)
    lines[#lines + 1] = "## Jupyter notebooks"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "| Key | Action |"
    lines[#lines + 1] = "| --- | --- |"
    for _, map in ipairs(jupyter) do
      lines[#lines + 1] = ("| `%s` | %s |"):format(pretty(map.lhs), map.desc)
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Cell motions: `]h` / `[h`. Cell text objects: `vih` / `vah`."
    lines[#lines + 1] = ""
    lines[#lines + 1] = "VS Code's notebook chords are mapped too: `Ctrl+CR` runs the cell and"
    lines[#lines + 1] = "`Shift+CR` runs it and advances, where the terminal can encode them."
    lines[#lines + 1] = ""
  end

  vim.list_extend(lines, {
    "## Notes",
    "",
    "- `Ctrl+Shift+*`, `Ctrl+.`, `Ctrl+Tab`, `Ctrl+CR` and `Shift+CR` cannot be encoded",
    "  by Windows Terminal. They work in WezTerm, Kitty and Ghostty; the",
    '  "Always works" column is the fallback everywhere.',
    "- `Ctrl+/` takes over LazyVim's default terminal binding, which is why the",
    '  terminal is on `Ctrl+J` (VS Code\'s "toggle panel").',
    "- Left alone on purpose, because they are core Vim motions: `Ctrl+A`,",
    "  `Ctrl+F`, `Ctrl+D`, `Ctrl+U`, `Ctrl+O`, `Ctrl+I`, `Ctrl+R`, `Ctrl+V`,",
    "  `Ctrl+W`, `Ctrl+E`, `Ctrl+Y`.",
  })

  return lines
end

--- Open the cheatsheet in a floating window.
function M.show()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, render())

  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].buftype = "nofile"

  local width = math.min(96, math.floor(vim.o.columns * 0.9))
  local height = math.min(#vim.api.nvim_buf_get_lines(buf, 0, -1, false) + 1, math.floor(vim.o.lines * 0.85))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Keyboard shortcuts ",
    title_pos = "center",
  })

  vim.wo[win].conceallevel = 2
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].cursorline = true

  for _, lhs in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", lhs, function()
      pcall(vim.api.nvim_win_close, win, true)
    end, { buffer = buf, nowait = true, desc = "Close" })
  end
end

return M
