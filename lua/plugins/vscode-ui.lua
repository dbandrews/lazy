-- Cosmetic/UX parity with VS Code. Everything here is opt-out: delete this file
-- and you get stock LazyVim back.

return {
  -- ╭────────────────────────────────────────────────────────╮
  -- │ VS Code Dark+ colours                                  │
  -- ╰────────────────────────────────────────────────────────╯
  { "Mofiqul/vscode.nvim", opts = { italic_comments = true, underline_links = true } },
  {
    "LazyVim/LazyVim",
    opts = {
      -- swap for "tokyonight" / "catppuccin" (both installed) if you'd rather
      colorscheme = "vscode",
    },
  },

  -- ╭────────────────────────────────────────────────────────╮
  -- │ Explorer sidebar                                       │
  -- ╰────────────────────────────────────────────────────────╯
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = { width = 32 },
      filesystem = {
        -- reveal the file you're editing, like VS Code's Explorer does
        follow_current_file = { enabled = true, leave_dirs_open = true },
        hijack_netrw_behavior = "open_default",
        filtered_items = {
          visible = false,
          hide_dotfiles = false,
          hide_gitignored = true,
          hide_by_name = { ".git", "__pycache__", ".pytest_cache", ".ruff_cache", ".mypy_cache" },
        },
      },
      default_component_configs = {
        indent = { with_expanders = true },
        git_status = { symbols = { unstaged = "M", staged = "A", untracked = "U" } },
      },
    },
  },

  -- ╭────────────────────────────────────────────────────────╮
  -- │ Editor tabs                                            │
  -- ╰────────────────────────────────────────────────────────╯
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        always_show_bufferline = true,
        show_buffer_close_icons = true,
        separator_style = "thin",
        diagnostics_indicator = function(count, level)
          local icon = level:match("error") and " " or " "
          return " " .. icon .. count
        end,
      },
    },
  },

  -- ╭────────────────────────────────────────────────────────╮
  -- │ Misc niceties                                          │
  -- ╰────────────────────────────────────────────────────────╯
  {
    "folke/snacks.nvim",
    opts = {
      scroll = { enabled = true }, -- smooth scrolling
      indent = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true, timeout = 3000 },
      words = { enabled = true },
    },
  },

  -- Sticky scroll: keep the enclosing def/class pinned at the top
  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = { max_lines = 3, multiline_threshold = 1, mode = "cursor" },
  },
}
