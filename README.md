# Neovim Configuration

## Prerequisites

- macOS

## Step 1: Install Homebrew

Open Terminal and run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the on-screen instructions. After installation, make sure to run the commands it tells you to add Homebrew to your PATH (it will print them at the end).

## Step 2: Install Xcode Command Line Tools

This provides `git`, `clang` (C/C++ compiler), `make`, and other essentials:

```bash
xcode-select --install
```

A dialog will pop up — click **Install** and wait for it to finish.

## Step 3: Install Kitty, Neovim, and Dependencies

```bash
brew install --cask kitty
brew install neovim ripgrep fd fzf lazygit
```

| Tool | What it's for |
|------|---------------|
| `kitty` | Terminal emulator |
| `neovim` | The editor itself (0.10+ required) |
| `ripgrep` | Live grep search (Telescope) |
| `fd` | File finding (Telescope) |
| `fzf` | Fuzzy matching (telescope-fzf-native) |
| `lazygit` | Git TUI (opened with `<Space>lg`) |

## Step 4: Configure Git

Set your name and email so Git knows who you are:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Step 5: Set Default Editor

Set Neovim as your default editor and install `neovim-remote` so lazygit can open files in your existing Neovim instance:

```bash
echo 'export EDITOR="nvim"' >> ~/.zshrc
echo 'export VISUAL="nvim"' >> ~/.zshrc
source ~/.zshrc
pip3 install neovim-remote
```

The Neovim config automatically detects `nvr` and uses it when running inside a Neovim terminal (like lazygit), so files open in a split in your current editor instead of nesting a new one.

## Step 6: Install a Nerd Font

A [Nerd Font](https://www.nerdfonts.com/) is required for icons in the status line and file explorer.

```bash
brew install --cask font-fira-code-nerd-font
```

Kitty is already configured to use this font (see Step 9).

## Step 7: Install Language Toolchains (as needed)

Install the languages you work with. The config has LSP support for all of these:

```bash
# Node.js (for TypeScript/JavaScript/ESLint)
brew install node

# Go
brew install go

# Python
brew install python

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

**C/C++** is already covered — the Xcode Command Line Tools from Step 2 provide `clang` and `clang++`.

You only need to install the ones you'll actually use.

## Step 8: Clone the Config

Back up any existing Neovim config first:

```bash
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null
mv ~/.local/share/nvim ~/.local/share/nvim.bak 2>/dev/null
mv ~/.local/state/nvim ~/.local/state/nvim.bak 2>/dev/null
mv ~/.cache/nvim ~/.cache/nvim.bak 2>/dev/null
```

Then clone:

```bash
git clone https://github.com/garkra/dotfiles.git ~/.config/nvim
```

## Step 9: Link the Kitty Config

The repo includes a Kitty config. Symlink it so Kitty picks it up:

```bash
mkdir -p ~/.config/kitty
ln -sf ~/.config/nvim/kitty/kitty.conf ~/.config/kitty/kitty.conf
```

## Step 10: Create the Undo Directory

The config uses persistent undo. Create the directory it expects:

```bash
mkdir -p ~/.vim/undodir
```

## Step 11: Launch Neovim

```bash
nvim
```

On first launch:
1. **lazy.nvim** will automatically bootstrap and install all plugins
2. **Mason** will automatically install these LSP servers: `lua_ls`, `ts_ls`, `gopls`, `pyright`, `rust_analyzer`, `eslint`, `clangd`
3. **Treesitter** will automatically install parsers for: Lua, TypeScript, TSX, JavaScript, Go, Python, Rust, C, C++, vimdoc

Wait for everything to finish installing (you'll see progress in the status area), then restart Neovim.

## Step 12: Set Up GitHub Copilot

On first use, Copilot will prompt you to authenticate:

```
:Copilot setup
```

Follow the instructions to link your GitHub account. Requires a [GitHub Copilot subscription](https://github.com/features/copilot).

## Keybindings

Leader key is `Space`.

### General

| Key | Mode | Action |
|-----|------|--------|
| `jk` | Insert | Exit insert mode |
| `Space pv` | Normal | Open file explorer (Oil) |
| `-` | Normal | Open parent directory (Oil) |
| `J` / `K` | Visual | Move selection down / up |
| `Ctrl-d` / `Ctrl-u` | Normal | Scroll down / up (centered) |
| `Space y` | Normal/Visual | Yank to system clipboard |
| `Space Y` | Normal | Yank line to system clipboard |
| `Space yf` | Normal | Copy current filepath |
| `Space p` | Visual | Paste without overwriting register |
| `Space d` | Normal/Visual | Delete to void register |
| `Space f` | Normal | Format buffer |
| `Space u` | Normal | Toggle undo tree |

### File Navigation (Telescope)

| Key | Mode | Action |
|-----|------|--------|
| `Space pf` | Normal | Find files |
| `Space gf` | Normal | Find git files |
| `Space pg` | Normal | Live grep |
| `Space fb` | Normal | Browse open buffers |
| `Ctrl-x` | Picker | Open in horizontal split |
| `Ctrl-v` | Picker | Open in vertical split |

### Harpoon (Quick File Switching)

| Key | Mode | Action |
|-----|------|--------|
| `Space ha` | Normal | Add file to harpoon |
| `Space hr` | Normal | Remove file from harpoon |
| `Ctrl-e` | Normal | Toggle harpoon menu |
| `Ctrl-j/k/l/;` | Normal | Jump to harpoon file 1/2/3/4 |

### LSP

| Key | Mode | Action |
|-----|------|--------|
| `gd` | Normal | Go to definition |
| `K` | Normal | Hover documentation |
| `Space ca` | Normal | Code action |
| `Space rr` | Normal | Find references |
| `Space rn` | Normal | Rename symbol |
| `Space dd` | Normal | Open diagnostic float |
| `Space dq` | Normal | Send diagnostics to quickfix |
| `[d` / `]d` | Normal | Prev / next diagnostic |
| `Ctrl-h` | Insert | Signature help |

### Completion (nvim-cmp)

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl-n` / `Ctrl-p` | Insert | Next / prev completion item |
| `Ctrl-Space` | Insert | Trigger completion |
| `Ctrl-e` | Insert | Abort completion |
| `Enter` | Insert | Confirm selection |
| `Tab` | Insert | Accept Copilot suggestion |

### Git

| Key | Mode | Action |
|-----|------|--------|
| `Space gs` | Normal | Git status (Fugitive) |
| `Space gb` | Normal | Git blame |
| `Space lg` | Normal | Open lazygit |

### Flash (Motion)

| Key | Mode | Action |
|-----|------|--------|
| `Space s` | Normal | Flash jump |
| `f` / `F` / `t` / `T` | Normal | Enhanced with flash labels |
| `/` | Normal | Search with flash labels |

### Splits

| Key | Mode | Action |
|-----|------|--------|
| `Space sv` | Normal | Vertical split |
| `Space sh` | Normal | Horizontal split |
| `Space sx` | Normal | Close split |
| `Space se` | Normal | Equalize split sizes |
| `Ctrl-Up/Down` | Normal | Resize vertically |
| `Ctrl-Left/Right` | Normal | Resize horizontally |

### Tabs

| Key | Mode | Action |
|-----|------|--------|
| `Shift-H` / `Shift-L` | Normal | Prev / next tab |
| `Space tn` | Normal | New tab |
| `Space tc` | Normal | Close tab |
| `Space to` | Normal | Close other tabs |

### Kitty Terminal

| Key | Action |
|-----|--------|
| `Cmd+D` | Vertical split |
| `Cmd+Shift+D` | Horizontal split |
| `Cmd+W` | Close split |
| `Cmd+Shift+H/L/K/J` | Navigate splits (left/right/up/down) |
| `Cmd+Alt+H/L/K/J` | Move split (left/right/up/down) |
| `Cmd+Shift+Arrow` | Resize split |
| `Cmd+Shift+]` / `[` | Next / prev tab |
| `Cmd+1-9` | Go to tab by number |
| `Cmd+Shift+R` | Rename tab |

## Plugin List

| Plugin | Purpose |
|--------|---------|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP configuration |
| [mason.nvim](https://github.com/williamboman/mason.nvim) | LSP/tool installer |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | Autocompletion |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | Snippet engine |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting |
| [conform.nvim](https://github.com/stevearc/conform.nvim) | Code formatting |
| [copilot.vim](https://github.com/github/copilot.vim) | GitHub Copilot |
| [harpoon](https://github.com/ThePrimeagen/harpoon) | Quick file navigation |
| [oil.nvim](https://github.com/stevearc/oil.nvim) | File explorer |
| [flash.nvim](https://github.com/folke/flash.nvim) | Enhanced motions |
| [vim-fugitive](https://github.com/tpope/vim-fugitive) | Git integration |
| [gitsigns.nvim](https://github.com/lewis6458/gitsigns.nvim) | Git gutter signs |
| [undotree](https://github.com/mbbill/undotree) | Undo history |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Keybinding hints |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Status line |
| [gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) | Colorscheme |
| [everforest-nvim](https://github.com/neanias/everforest-nvim) | Colorscheme (alt) |

## Troubleshooting

- **Icons look broken**: Make sure your terminal is using a Nerd Font
- **Telescope grep not working**: Make sure `ripgrep` is installed (`brew install ripgrep`)
- **LSP not starting**: Check `:Mason` to see if the server is installed. Make sure the language toolchain is installed (e.g., `node` for TypeScript)
- **Copilot not working**: Run `:Copilot setup` and authenticate with GitHub
- **Plugins not installing**: Run `:Lazy sync` to force a plugin sync
- **Treesitter errors**: Run `:TSUpdate` to update parsers
