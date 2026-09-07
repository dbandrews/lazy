-- Jupyter notebooks, VS Code style.
--
-- How the pieces fit together:
--   jupytext.nvim ......... opens `*.ipynb` as a `# %%`-delimited **python**
--                           buffer and converts it back on `:w`. Because the
--                           buffer really is python, basedpyright/ruff/treesitter
--                           all work inside notebooks with no extra machinery.
--   molten-nvim ........... runs cells against a real Jupyter kernel and shows
--                           the output inline as virtual text.
--   NotebookNavigator ..... cell motions, run-cell/run-and-advance, add/split
--                           cells, and cell-marker highlighting.
--
-- Outputs survive the round trip: they are imported when the notebook is opened
-- and exported back into the .ipynb on save (see lua/config/autocmds.lua).

return {
  -- ╭────────────────────────────────────────────────────────╮
  -- │ Kernel + cell execution                                │
  -- ╰────────────────────────────────────────────────────────╯
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    lazy = false, -- remote (python) plugin: its commands come from the rplugin manifest
    build = ":UpdateRemotePlugins",
    -- stylua: ignore
    keys = {
      { "<leader>ji", "<cmd>MoltenInit<cr>",                     desc = "Init kernel" },
      { "<leader>jI", "<cmd>MoltenDeinit<cr>",                   desc = "Shut down kernel" },
      { "<leader>jR", "<cmd>MoltenRestart!<cr>",                 desc = "Restart kernel" },
      { "<leader>jk", "<cmd>MoltenInterrupt<cr>",                desc = "Interrupt kernel" },
      { "<leader>jl", "<cmd>MoltenEvaluateLine<cr>",             desc = "Run line" },
      { "<leader>jr", "<cmd>MoltenReevaluateCell<cr>",           desc = "Re-run cell" },
      { "<leader>jA", "<cmd>MoltenReevaluateAll<cr>",            desc = "Re-run all cells" },
      { "<leader>jv", ":<C-u>MoltenEvaluateVisual<cr>gv",        desc = "Run selection", mode = "x" },
      { "<leader>jo", ":noautocmd MoltenEnterOutput<cr>",        desc = "Enter output window" },
      { "<leader>js", "<cmd>MoltenShowOutput<cr>",               desc = "Show output" },
      { "<leader>jh", "<cmd>MoltenHideOutput<cr>",               desc = "Hide output" },
      { "<leader>jd", "<cmd>MoltenDelete<cr>",                   desc = "Delete cell output" },
      { "<leader>jy", "<cmd>MoltenYankOutput<cr>",               desc = "Yank output" },
      { "<leader>jp", "<cmd>MoltenImagePopup<cr>",               desc = "Open image output" },
      { "<leader>jw", "<cmd>MoltenOpenInBrowser<cr>",            desc = "Open HTML output in browser" },
      { "<leader>jt", "<cmd>MoltenToggleVirtual<cr>",            desc = "Toggle inline output" },
      { "<leader>j?", "<cmd>MoltenInfo<cr>",                     desc = "Kernel info" },
      { "]j",         "<cmd>MoltenNext<cr>",                     desc = "Next molten cell" },
      { "[j",         "<cmd>MoltenPrev<cr>",                     desc = "Prev molten cell" },
    },
  },

  -- ╭────────────────────────────────────────────────────────╮
  -- │ .ipynb <-> plaintext                                   │
  -- ╰────────────────────────────────────────────────────────╯
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false, -- must own the BufReadCmd for *.ipynb before any file is read
    opts = {
      -- "hydrogen" == the `# %%` percent format, but with `%magics` left intact
      -- so they still run. `auto`/nil means: python notebook -> python buffer.
      style = "hydrogen",
      output_extension = "auto",
      force_ft = nil,
    },
  },

  -- ╭────────────────────────────────────────────────────────╮
  -- │ Cells: motions, running, editing                       │
  -- ╰────────────────────────────────────────────────────────╯
  {
    "GCBallesteros/NotebookNavigator.nvim",
    dependencies = { "benlubas/molten-nvim" },
    lazy = false,
    -- stylua: ignore
    keys = {
      -- VS Code: Ctrl+Enter runs the cell, Shift+Enter runs it and moves on.
      -- (Both chords need a terminal that sends CSI-u -- WezTerm, kitty, Ghostty.
      -- The <leader>j pair below always works.)
      { "<C-CR>",     function() require("util.notebook").run_cell() end,     desc = "Run cell" },
      { "<S-CR>",     function() require("util.notebook").run_and_move() end,  desc = "Run cell and advance" },
      { "<leader>je", function() require("util.notebook").run_cell() end,      desc = "Run cell" },
      { "<leader>jj", function() require("util.notebook").run_and_move() end,  desc = "Run cell and advance" },
      { "<leader>ja", function() require("util.notebook").run_all() end,       desc = "Run all cells" },
      { "<leader>jb", function() require("util.notebook").run_below() end,     desc = "Run cell and below" },
      { "<leader>jP", function() require("util.notebook").run_above() end,     desc = "Run all cells above" },
      { "<leader>jn", function() require("notebook-navigator").add_cell_below() end, desc = "New cell below" },
      { "<leader>jN", function() require("notebook-navigator").add_cell_above() end, desc = "New cell above" },
      { "<leader>jS", function() require("notebook-navigator").split_cell() end,    desc = "Split cell" },
      { "<leader>jm", function() require("notebook-navigator").merge_cell("d") end, desc = "Merge with cell below" },
      { "<leader>jc", function() require("notebook-navigator").comment_cell() end,  desc = "Comment cell" },
      { "]h",         function() require("notebook-navigator").move_cell("d") end,  desc = "Next cell" },
      { "[h",         function() require("notebook-navigator").move_cell("u") end,  desc = "Prev cell" },
    },
    opts = {
      repl_provider = "molten",
      cell_markers = { python = "# %%" },
      -- highlighting is provided by mini.hipatterns below
      syntax_highlight = false,
      cell_highlight_group = "CursorLine",
      -- hydra.nvim's "cell mode" is deliberately not wired up: it emits a
      -- deprecation warning on every startup. Just hold <leader>jj instead.
      activate_hydra_keys = nil,
    },
  },

  -- Highlight the `# %%` cell markers as full-width separators
  {
    "nvim-mini/mini.hipatterns",
    optional = true,
    dependencies = { "GCBallesteros/NotebookNavigator.nvim" },
    opts = function(_, opts)
      opts.highlighters = opts.highlighters or {}
      opts.highlighters.cells = require("notebook-navigator").minihipatterns_spec
      return opts
    end,
  },

  -- `ih` / `ah` text objects for "inside / around code cell"
  {
    "nvim-mini/mini.ai",
    optional = true,
    dependencies = { "GCBallesteros/NotebookNavigator.nvim" },
    opts = function(_, opts)
      opts.custom_textobjects = opts.custom_textobjects or {}
      opts.custom_textobjects.h = require("notebook-navigator").miniai_spec
      return opts
    end,
  },

  -- ╭────────────────────────────────────────────────────────╮
  -- │ which-key labels                                       │
  -- ╰────────────────────────────────────────────────────────╯
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>j", group = "jupyter", icon = { icon = "󰠮 ", color = "orange" } },
      },
    },
  },
}
