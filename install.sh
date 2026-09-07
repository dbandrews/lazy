#!/usr/bin/env bash
# Host-level dependencies for this Neovim config.
#
# Idempotent: re-running only installs what is missing. Everything lands under
# ~/.local and ~/.venvs, except the apt packages.
set -euo pipefail

BIN="$HOME/.local/bin"
NVIM_PREFIX="$HOME/.local/nvim"
NVIM_VERSION="${NVIM_VERSION:-v0.12.5}"
# nvim-treesitter's main branch shells out to the tree-sitter CLI. Mason's build
# of it needs glibc 2.39; 0.25.10 is the newest release that still runs on the
# 2.35 that Ubuntu 22.04 ships. LazyVim prefers whatever is already on $PATH.
TREE_SITTER_VERSION="${TREE_SITTER_VERSION:-v0.25.10}"
NVIM_VENV="$HOME/.venvs/nvim"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

case ":$PATH:" in
  *":$BIN:"*) ;;
  *) log "WARNING: $BIN is not on \$PATH -- add it before continuing" ;;
esac
mkdir -p "$BIN"

# ── system packages ────────────────────────────────────────────────────────────
log "apt packages"
sudo apt-get update -qq >/dev/null
sudo apt-get install -y -qq >/dev/null \
  build-essential git curl unzip ripgrep fd-find xdg-utils \
  python3-venv python3-pip
# ripgrep and fd power the pickers; fd is named fdfind on Debian/Ubuntu
[ -e "$BIN/fd" ] || ln -s "$(command -v fdfind)" "$BIN/fd"

if grep -qi microsoft /proc/version 2>/dev/null; then
  log "WSL: clipboard + 'open in Windows' support"
  sudo apt-get install -y -qq wslu >/dev/null
  if [ ! -x "$BIN/win32yank.exe" ]; then
    # Neovim's WSL clipboard provider looks for win32yank
    tmp=$(mktemp -d)
    curl -sfL -o "$tmp/w.zip" \
      https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip
    unzip -o -q "$tmp/w.zip" win32yank.exe -d "$BIN"
    chmod +x "$BIN/win32yank.exe"
    rm -rf "$tmp"
  fi
  # so PIL's Image.show() (":MoltenImagePopup") and plotly HTML reach Windows
  mkdir -p "$HOME/.local/share/applications"
  cat > "$HOME/.local/share/applications/wslview.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Open in Windows (wslview)
Comment=Hand the file to the default Windows application
Exec=wslview %f
Terminal=false
NoDisplay=true
MimeType=image/png;image/jpeg;image/gif;image/svg+xml;image/webp;application/pdf;text/html;
EOF
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  for mime in image/png image/jpeg image/gif image/svg+xml image/webp application/pdf text/html; do
    xdg-mime default wslview.desktop "$mime" 2>/dev/null || true
  done
fi

# ── neovim ─────────────────────────────────────────────────────────────────────
if [ "$("$BIN/nvim" --version 2>/dev/null | head -1)" != "NVIM ${NVIM_VERSION}" ]; then
  log "neovim ${NVIM_VERSION}"
  tmp=$(mktemp -d)
  curl -sfL -o "$tmp/nvim.tar.gz" \
    "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
  rm -rf "$NVIM_PREFIX"
  mkdir -p "$NVIM_PREFIX"
  tar xzf "$tmp/nvim.tar.gz" -C "$NVIM_PREFIX" --strip-components=1
  ln -sf "$NVIM_PREFIX/bin/nvim" "$BIN/nvim"
  rm -rf "$tmp"
else
  log "neovim ${NVIM_VERSION} already installed"
fi

# ── tree-sitter CLI ────────────────────────────────────────────────────────────
if ! "$BIN/tree-sitter" --version >/dev/null 2>&1; then
  log "tree-sitter CLI ${TREE_SITTER_VERSION}"
  curl -sfL "https://github.com/tree-sitter/tree-sitter/releases/download/${TREE_SITTER_VERSION}/tree-sitter-linux-x64.gz" \
    | gunzip -c > "$BIN/tree-sitter"
  chmod +x "$BIN/tree-sitter"
else
  log "tree-sitter CLI already installed ($("$BIN/tree-sitter" --version))"
fi

# ── python tooling ─────────────────────────────────────────────────────────────
if ! command -v uv >/dev/null 2>&1; then
  log "uv"
  curl -sfLS https://astral.sh/uv/install.sh | sh
fi

# ruff and jupytext are called as CLIs (by conform.nvim and jupytext.nvim), so
# they belong on $PATH rather than in a project venv
log "ruff + jupytext on \$PATH"
uv tool install --quiet ruff || uv tool upgrade --quiet ruff || true
uv tool install --quiet jupytext || uv tool upgrade --quiet jupytext || true

# A venv used only by Neovim's python provider, so that molten keeps working no
# matter which project venv happens to be active.
log "neovim python provider venv at $NVIM_VENV"
uv venv --quiet --python 3.12 "$NVIM_VENV"
uv pip install --quiet --python "$NVIM_VENV/bin/python" \
  pynvim jupyter_client ipykernel jupytext nbformat \
  pyperclip cairosvg pnglatex plotly kaleido pillow \
  numpy pandas matplotlib debugpy

# a `python3` kernelspec that notebooks fall back to
"$NVIM_VENV/bin/python" -m ipykernel install --user --name python3 \
  --display-name "Python 3 (nvim)" >/dev/null

# ── node (for the neovim npm host; silences :checkhealth) ──────────────────────
if command -v npm >/dev/null 2>&1; then
  log "neovim npm package"
  npm ls -g neovim >/dev/null 2>&1 || npm i -g --silent neovim
fi

log "done. run 'nvim' -- lazy.nvim will install the plugins on first start."
log "afterwards, ':checkhealth' should come back clean."
