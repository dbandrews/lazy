# Neovim — a VS Code-shaped Python IDE

LazyVim, configured so that the Python workflow (autoformat, go-to-definition,
syntax highlighting, debugging, Jupyter notebooks) works the way it does in
VS Code, and so that the keys you already press mostly do the right thing.

Clone to `~/.config/nvim`, run `./install.sh` to get the host-level dependencies,
start `nvim`, and let lazy.nvim install the plugins.

```sh
git clone https://github.com/dbandrews/lazy.git ~/.config/nvim
~/.config/nvim/install.sh
nvim
```

Requires Neovim >= 0.11.2 (LazyVim 16); `install.sh` installs 0.12.x.

## What you get

| VS Code feature | Here |
| --- | --- |
| Pylance | `basedpyright`, with inlay hints, `typeCheckingMode = "standard"` |
| Ruff extension | `ruff` LSP for diagnostics/code actions, `ruff format` + import sort on save |
| Go to Definition / References | `F12` / `Shift-F12` (also `gd` / `gr`) |
| Rename Symbol | `F2`, with a live preview of every edit |
| Problems panel | `Ctrl-Shift-M` (also `<leader>xx`) |
| Run and Debug | `F5` / `F9` / `F10` / `F11`, `debugpy`, variables + call stack + REPL |
| Testing sidebar | `neotest` + `pytest`, `<leader>t` |
| Jupyter notebooks | `.ipynb` opens as editable cells, run them in place, outputs inline |
| Outline | `<leader>cs` |
| Breadcrumbs | `nvim-navic` in the statusline |
| Sticky scroll | `nvim-treesitter-context` |
| Interpreter picker | `<leader>cv` |
| Dark+ theme | `Mofiqul/vscode.nvim` |

## Layout

```text
init.lua                    entry point
lazyvim.json                which LazyVim extras are on -- edit with `:LazyExtras`
lua/config/lazy.lua         lazy.nvim bootstrap
lua/config/options.lua      leaders, python host, molten globals, editor options
lua/config/keymaps.lua      the VS Code keymap layer
lua/config/autocmds.lua     python buffer setup + all the .ipynb plumbing
lua/plugins/python.lua      LSP / format / debug / test configuration
lua/plugins/jupyter.lua     molten + jupytext + NotebookNavigator
lua/plugins/vscode-ui.lua   theme, explorer, tabs -- pure cosmetics, safe to delete
lua/util/notebook.lua       cell runner (see "Why a custom cell runner")
lua/plugins/example.lua     stock LazyVim reference file; returns {}, does nothing
```

## Python

Formatting runs on save through conform.nvim: `ruff_organize_imports` then
`ruff_format`. `:LazyFormatInfo` shows what will run for the current buffer, and
`<leader>uf` toggles autoformat. To also apply ruff's lint fixes (the equivalent
of VS Code's `source.fixAll.ruff`), add `"ruff_fix"` to `formatters_by_ft.python`
in `lua/plugins/python.lua`.

basedpyright is pointed at your project's interpreter automatically: `$VIRTUAL_ENV`,
then `$CONDA_PREFIX`, then `.venv/` or `venv/` in the project root. `<leader>cv`
switches it at runtime and also searches `~/.venvs`.

Debugging uses the `debugpy` that mason installs as the adapter, and runs *your*
code with the project interpreter. `F5` offers `Launch file (project cwd)` first;
a `.vscode/launch.json` in the project is picked up as well.

## Jupyter notebooks

Open any `.ipynb` and you get a normal Python buffer with `# %%` cell markers —
jupytext converts on read and back again on write. Because the buffer genuinely
is Python, basedpyright, ruff, treesitter and format-on-save all work inside
notebooks with no extra machinery.

Molten runs the cells against a real Jupyter kernel and renders output inline as
virtual text. Outputs are imported when you open a notebook and exported back
into the `.ipynb` when you save, so they survive the round trip.

```text
:NewNotebook path/name      create and open an empty notebook
<leader>jj                  run cell and move to the next one   (also Shift-CR)
<leader>je                  run cell, stay put                  (also Ctrl-CR)
<leader>ja / jb / jP        run all / this-and-below / everything above
<leader>jl / jv             run line / run visual selection
]h / [h                     next / previous cell
<leader>jn / jN             new cell below / above
<leader>jS / jm             split cell / merge with the cell below
<leader>jo / js / jh        enter output window / show / hide
<leader>jp                  open an image output in the Windows viewer
<leader>jw                  open an HTML output (plotly, ...) in the browser
<leader>ji / jR / jk / jI   init kernel / restart / interrupt / shut down
<leader>jt                  toggle inline output
vih / vah                   select inside / around the cell
```

The kernel is chosen automatically: the one named in the notebook's metadata, else
one named after the active virtualenv, else `python3`. To make a project venv's
kernel the one notebooks use, register it under the venv's own name:

```sh
uv pip install --python .venv/bin/python ipykernel
.venv/bin/python -m ipykernel install --user --name "$(basename "$PWD")"
```

While a notebook is open, jupytext keeps a sibling `<name>.py` next to it as its
scratch representation and removes it when the buffer unloads. Don't delete the
`.ipynb` from underneath an open buffer — that leaves the `.py` behind, and it
will shadow the notebook's real contents next time you open it.

### Why a custom cell runner

`lua/util/notebook.lua` replaces NotebookNavigator's molten integration. That one
evaluates `[cell_start, cell_end + 1]`, which parks the cell's end marker on the
*next* cell's `# %%` line, so output renders under the following cell. The custom
runner uses molten's four-argument `MoltenEvaluateRange` to end the range on the
cell's last non-blank line, which puts output directly under the code, and it
skips blank and comment-only cells so jupytext's YAML header and `# %% [markdown]`
prose are never sent to the kernel.

### Images

Windows Terminal implements neither the kitty nor the iTerm graphics protocol, so
plots cannot be drawn in the buffer. Molten is set to `image_provider = "none"`:
cell output shows the text representation, and `<leader>jp` hands the figure to
the Windows image viewer (`install.sh` wires `xdg-open` to `wslview` for that).
Plotly and other HTML output opens in the browser with `<leader>jw`.

If you move to WezTerm, Kitty or Ghostty, set `vim.g.molten_image_provider` to
`"wezterm"` (or `"image.nvim"`, after adding the plugin) in `lua/config/options.lua`
and images render inline.

## Keymaps

The VS Code layer lives entirely in `lua/config/keymaps.lua`; delete the file to
get stock LazyVim back. Every mapping has a `<leader>` equivalent, because some
chords depend on the terminal.

| Key | Action |
| --- | --- |
| `Ctrl-P` | Go to File |
| `Ctrl-Shift-P` | Command Palette |
| `Ctrl-Shift-F` | Search in Files |
| `Ctrl-Shift-O` | Go to Symbol |
| `Ctrl-Shift-M` | Problems |
| `Ctrl-B` / `Ctrl-Shift-E` | toggle / focus Explorer |
| `Ctrl-J` | toggle terminal panel |
| `Ctrl-S` | Save |
| `Ctrl-/` | Toggle comment (normal, visual, insert) |
| `Alt-Up/Down` | Move line(s) |
| `Alt-Shift-Up/Down` | Duplicate line(s) |
| `Ctrl-Tab` / `Ctrl-Shift-Tab` | Cycle buffers (or `S-h` / `S-l`) |
| `F12` / `Shift-F12` | Definition / References |
| `F2` | Rename (`Ctrl-W` clears the old name) |
| `Shift-Alt-F` | Format document |
| `Ctrl-.` | Code action |
| `F5` / `Shift-F5` / `Ctrl-Shift-F5` | Debug start / stop / restart |
| `F9` / `Shift-F9` | Breakpoint / conditional breakpoint |
| `F10` / `F11` / `Shift-F11` | Step over / into / out |
| `F6` | Toggle debug UI |

`Ctrl-/` takes over LazyVim's default terminal binding, which is why the terminal
moved to `Ctrl-J` (VS Code's "toggle panel").

Chords a terminal cannot encode without the kitty keyboard protocol — `Ctrl-Shift-*`,
`Ctrl-.`, `Ctrl-CR`, `Shift-CR`, `Ctrl-Tab` — silently do nothing in Windows Terminal.
They work in WezTerm, Kitty and Ghostty. The `<leader>` equivalents always work.

Core Vim motions are left alone on purpose: `Ctrl-A`, `Ctrl-F`, `Ctrl-D`, `Ctrl-U`,
`Ctrl-O`, `Ctrl-I`, `Ctrl-R`, `Ctrl-V`, `Ctrl-W`, `Ctrl-E`, `Ctrl-Y`.

## Notes on the plumbing

Two things about `.ipynb` buffers need explaining, because both look like bugs:

- **`BufReadCmd` replaces the read.** jupytext registers one, so `BufReadPre` and
  `BufReadPost` never fire — and those are the events lazy.nvim uses to load
  nvim-lspconfig. Without help, notebooks open with no LSP at all. `autocmds.lua`
  replays those events once per buffer.
- **`BufWriteCmd` replaces the write**, and with it `BufWritePre`, which is where
  LazyVim's format-on-save lives. `autocmds.lua` replays that too, before
  jupytext's own handler does the conversion.

Neovim's built-in filetype rule also maps `*.ipynb` to `json`, which would hand
notebooks to `jsonls`. `options.lua` overrides it to `python`.

`nvim-treesitter`'s main branch compiles parsers with the `tree-sitter` CLI. Mason
installs a build that needs glibc 2.39, which Ubuntu 22.04 doesn't have; `install.sh`
puts a working CLI in `~/.local/bin` instead, and LazyVim then prefers it.
