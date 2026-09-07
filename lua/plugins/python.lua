-- Python: LSP (basedpyright), formatting (ruff), debugging (debugpy), testing (pytest).
-- The `lang.python` LazyVim extra does the wiring; this file makes it behave like
-- VS Code + Pylance + the Ruff extension.

local function first_executable(paths)
  for _, p in ipairs(paths) do
    p = vim.fn.expand(p)
    if vim.fn.executable(p) == 1 then
      return p
    end
  end
end

-- The python interpreter that *hosts* the debug adapter. It only needs debugpy
-- installed; the interpreter used to run your code is resolved separately, from
-- the active venv (see `resolve_python` below).
local function debugpy_python()
  return first_executable({
    vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python",
    "~/.venvs/nvim/bin/python",
  }) or "python3"
end

-- ruff refuses plaintext on stdin when the filename says `.ipynb` (it expects
-- notebook JSON there), so pretend notebook buffers are plain .py files.
local function stdin_filename(ctx)
  return (ctx.filename:gsub("%.ipynb$", ".py"))
end

return {
  -- ╭────────────────────────────────────────────────────────╮
  -- │ Tooling                                                │
  -- ╰────────────────────────────────────────────────────────╯
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "debugpy", "ruff", "basedpyright" } },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "python", "toml", "ninja", "rst", "requirements" } },
  },

  -- ╭────────────────────────────────────────────────────────╮
  -- │ LSP -- basedpyright is the closest thing to Pylance    │
  -- ╰────────────────────────────────────────────────────────╯
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = true },
      servers = {
        basedpyright = {
          -- VS Code asks you to "Select Interpreter" and then Pylance analyses
          -- against that environment. Do the same automatically: prefer the
          -- active venv, then one living in the project root. `<leader>cv`
          -- (venv-selector) overrides this at runtime.
          before_init = function(_, config)
            local root = config.root_dir or vim.fn.getcwd()
            local candidates = {}
            for _, dir in ipairs({ os.getenv("VIRTUAL_ENV"), os.getenv("CONDA_PREFIX") }) do
              if dir then
                candidates[#candidates + 1] = dir .. "/bin/python"
              end
            end
            candidates[#candidates + 1] = root .. "/.venv/bin/python"
            candidates[#candidates + 1] = root .. "/venv/bin/python"

            for _, python in ipairs(candidates) do
              if vim.fn.executable(python) == 1 then
                config.settings = config.settings or {}
                config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, {
                  pythonPath = python,
                })
                return
              end
            end
          end,
          settings = {
            basedpyright = {
              -- ruff already handles style/lint; keep the type checker useful
              -- rather than overwhelming (basedpyright's default is "recommended",
              -- which is far stricter than what VS Code/Pylance ships with).
              analysis = {
                typeCheckingMode = "standard",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                autoImportCompletions = true,
                diagnosticSeverityOverrides = {
                  -- a bare expression on the last line of a cell is *the* idiom
                  -- for showing a value in a notebook, not a mistake
                  reportUnusedExpression = "none",
                  reportMissingTypeStubs = "none",
                },
                inlayHints = {
                  variableTypes = true,
                  callArgumentNames = true,
                  functionReturnTypes = true,
                  genericTypes = false,
                },
              },
            },
          },
        },
        ruff = {
          -- organise-imports & fix-all as code actions, like the VS Code Ruff extension
          init_options = { settings = { logLevel = "error" } },
        },
      },
    },
  },

  -- ╭────────────────────────────────────────────────────────╮
  -- │ Format on save with ruff                               │
  -- ╰────────────────────────────────────────────────────────╯
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format" },
      },
      formatters = {
        ruff_organize_imports = {
          command = "ruff",
          stdin = true,
          args = function(_, ctx)
            return {
              "check",
              "--force-exclude",
              "--select=I001",
              "--fix",
              "--exit-zero",
              "--no-cache",
              "--stdin-filename",
              stdin_filename(ctx),
              "-",
            }
          end,
        },
        ruff_format = {
          command = "ruff",
          stdin = true,
          args = function(_, ctx)
            return {
              "format",
              "--force-exclude",
              "--no-cache",
              "--stdin-filename",
              stdin_filename(ctx),
              "-",
            }
          end,
        },
      },
    },
  },

  -- ╭────────────────────────────────────────────────────────╮
  -- │ Debugging -- F5 / F9 / F10 / F11 as in VS Code         │
  -- ╰────────────────────────────────────────────────────────╯
  {
    "mfussenegger/nvim-dap-python",
    -- overrides the `setup("debugpy-adapter")` call from the LazyVim extra
    config = function()
      local dap_python = require("dap-python")
      dap_python.setup(debugpy_python(), {
        -- run the file with the project's own interpreter (.venv/venv/$VIRTUAL_ENV)
        resolve_python = function()
          return first_executable({
            os.getenv("VIRTUAL_ENV") and os.getenv("VIRTUAL_ENV") .. "/bin/python" or "",
            os.getenv("CONDA_PREFIX") and os.getenv("CONDA_PREFIX") .. "/bin/python" or "",
            vim.fn.getcwd() .. "/.venv/bin/python",
            vim.fn.getcwd() .. "/venv/bin/python",
          }) or debugpy_python()
        end,
      })
      dap_python.test_runner = "pytest"

      -- The equivalent of VS Code's "Python: Current File" launch config, plus a
      -- couple of variants that are tedious to set up by hand.
      local dap = require("dap")
      dap.configurations.python = dap.configurations.python or {}
      table.insert(dap.configurations.python, 1, {
        type = "python",
        request = "launch",
        name = "Launch file (project cwd)",
        program = "${file}",
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
        justMyCode = false,
      })
      table.insert(dap.configurations.python, 2, {
        type = "python",
        request = "launch",
        name = "Launch file with arguments",
        program = "${file}",
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
        justMyCode = false,
        args = function()
          return vim.split(vim.fn.input("Arguments: "), " +", { trimempty = true })
        end,
      })
    end,
  },

  -- Keep the debug UI where VS Code puts it: variables/scopes on the left,
  -- REPL + console at the bottom.
  {
    "rcarriga/nvim-dap-ui",
    opts = {
      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.35 },
            { id = "breakpoints", size = 0.15 },
            { id = "stacks", size = 0.3 },
            { id = "watches", size = 0.2 },
          },
          position = "left",
          size = 42,
        },
        {
          elements = {
            { id = "repl", size = 0.5 },
            { id = "console", size = 0.5 },
          },
          position = "bottom",
          size = 12,
        },
      },
    },
  },

  -- ╭────────────────────────────────────────────────────────╮
  -- │ Testing                                                │
  -- ╰────────────────────────────────────────────────────────╯
  {
    "nvim-neotest/neotest",
    opts = {
      adapters = {
        ["neotest-python"] = {
          runner = "pytest",
          args = { "-q" },
        },
      },
    },
  },

  -- ╭────────────────────────────────────────────────────────╮
  -- │ Virtualenv picker (<leader>cv)                         │
  -- ╰────────────────────────────────────────────────────────╯
  -- Also searches ~/.venvs and conda envs, not just the project tree, so the
  -- interpreter picker feels like VS Code's "Python: Select Interpreter".
  {
    "linux-cultist/venv-selector.nvim",
    opts = {
      options = { notify_user_on_venv_activation = true },
      search = {
        home_venvs = { command = "fd 'bin/python$' ~/.venvs --full-path --color never -E /proc -HI -a -L" },
      },
    },
  },
}
