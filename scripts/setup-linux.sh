#!/usr/bin/env bash
set -euo pipefail

# Setup script for Ubuntu/Debian Linux
# Works whether your login shell is bash or zsh
# Safe to re-run — checks versions and upgrades/replaces as needed

MIN_NVIM="0.11.3"
MIN_KITTY="0.35.0"

# ─── Helpers ──────────────────────────────────────────────────────────

color() { printf "\033[%sm%s\033[0m\n" "$1" "$2"; }
info()  { color "34" "  $1"; }
ok()    { color "32" "  ✓ $1"; }
warn()  { color "33" "  ⚠ $1"; }
err()   { color "31" "  ✗ $1"; }

# Compare two version strings: returns 0 if $1 >= $2
version_gte() {
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# Prompt user yes/no (defaults to yes)
confirm() {
    printf "\033[33m  %s [Y/n] \033[0m" "$1"
    read -r answer
    [[ -z "$answer" || "$answer" =~ ^[Yy] ]]
}

# Detect shell rc file
detect_shell_rc() {
    if [ "$(basename "${SHELL:-/bin/bash}")" = "zsh" ]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bashrc"
    fi
}

SHELL_RC="$(detect_shell_rc)"

add_to_rc() {
    if ! grep -qF "$1" "$SHELL_RC" 2>/dev/null; then
        echo "$1" >> "$SHELL_RC"
        info "Added to $SHELL_RC: $1"
    fi
}

echo ""
color "1" "=== Neovim Environment Setup (Ubuntu/Debian) ==="
echo ""
info "Detected shell config: $SHELL_RC"
echo ""

# ─── Neovim ───────────────────────────────────────────────────────────

install_nvim() {
    local version
    version="$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep -Po '"tag_name": "v\K[^"]*')"
    info "Downloading Neovim $version from GitHub releases..."
    curl -Lo /tmp/nvim-linux64.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    sudo rm -rf /opt/nvim
    sudo tar xzf /tmp/nvim-linux64.tar.gz -C /opt
    sudo mv /opt/nvim-linux-x86_64 /opt/nvim
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    rm -f /tmp/nvim-linux64.tar.gz
}

color "1" "--- Neovim ---"
if command -v nvim &>/dev/null; then
    NVIM_VER="$(nvim --version | head -1 | grep -oP 'v?\K[0-9]+\.[0-9]+\.[0-9]+')"
    if version_gte "$NVIM_VER" "$MIN_NVIM"; then
        ok "Neovim $NVIM_VER (>= $MIN_NVIM)"
    else
        warn "Neovim $NVIM_VER is too old (need >= $MIN_NVIM)"
        if confirm "Remove old Neovim and install from GitHub releases?"; then
            sudo apt remove -y neovim neovim-runtime 2>/dev/null || true
            sudo snap remove nvim 2>/dev/null || true
            install_nvim
            ok "Neovim upgraded to $(nvim --version | head -1)"
        fi
    fi
else
    info "Neovim not found. Installing from GitHub releases..."
    install_nvim
    ok "Neovim installed: $(nvim --version | head -1)"
fi
echo ""

# ─── Core apt packages ────────────────────────────────────────────────

color "1" "--- Core dependencies (apt) ---"
PACKAGES=(git curl build-essential ripgrep fd-find fzf lazygit python3 python3-pip python3-venv fontconfig)
MISSING=()
for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        MISSING+=("$pkg")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    info "Installing: ${MISSING[*]}"
    sudo apt update && sudo apt install -y "${MISSING[@]}"
    ok "Packages installed"
else
    ok "All core packages present"
fi

# fd-find installs as 'fdfind' on Ubuntu — create symlink so plugins find 'fd'
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
    info "Created symlink: fd -> fdfind"
fi
echo ""

# ─── Kitty ─────────────────────────────────────────────────────────────

color "1" "--- Kitty ---"
if command -v kitty &>/dev/null; then
    KITTY_VER="$(kitty --version | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')"
    if version_gte "$KITTY_VER" "$MIN_KITTY"; then
        ok "Kitty $KITTY_VER (>= $MIN_KITTY)"
    else
        warn "Kitty $KITTY_VER is too old (need >= $MIN_KITTY)"
        if confirm "Remove old Kitty and reinstall?"; then
            sudo apt remove -y kitty 2>/dev/null || true
            rm -rf ~/.local/kitty.app 2>/dev/null || true
            sudo apt update && sudo apt install -y kitty
            ok "Kitty upgraded to $(kitty --version)"
        fi
    fi
else
    info "Kitty not found. Installing..."
    sudo apt install -y kitty
    ok "Kitty installed: $(kitty --version)"
fi
echo ""


# ─── mise (runtime version manager) ───────────────────────────────────

color "1" "--- mise ---"
if command -v mise &>/dev/null; then
    ok "mise already installed ($(mise --version))"
else
    info "Installing mise..."
    curl https://mise.run | sh
    add_to_rc 'eval "$(~/.local/bin/mise activate zsh)"'
    export PATH="$HOME/.local/bin:$PATH"
    ok "mise installed"
fi

# Install Node.js LTS via mise (needed by Mason for LSP servers)
if mise which node &>/dev/null; then
    ok "Node.js $(mise which node && node --version) already installed via mise"
else
    info "Installing Node.js LTS via mise..."
    ~/.local/bin/mise use --global node@lts
    ok "Node.js installed: $(~/.local/bin/mise exec -- node --version)"
fi

# Install Go via mise (needed by Mason for gopls)
if mise which go &>/dev/null; then
    ok "Go $(mise exec -- go version | grep -oP '[0-9]+\.[0-9]+\.[0-9]+') already installed via mise"
else
    info "Installing Go via mise..."
    ~/.local/bin/mise use --global go@latest
    ok "Go installed: $(~/.local/bin/mise exec -- go version)"
fi
echo ""

# ─── Nerd Font ─────────────────────────────────────────────────────────

color "1" "--- Iosevka Nerd Font ---"
FONT_DIR="$HOME/.local/share/fonts/Iosevka"
if fc-list | grep -qi "Iosevka.*Nerd"; then
    ok "Iosevka Nerd Font already installed"
else
    info "Downloading Iosevka Nerd Font..."
    mkdir -p "$FONT_DIR"
    curl -Lo /tmp/Iosevka.tar.xz "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Iosevka.tar.xz"
    tar xf /tmp/Iosevka.tar.xz -C "$FONT_DIR"
    rm -f /tmp/Iosevka.tar.xz
    fc-cache -f
    ok "Iosevka Nerd Font installed"
fi
echo ""

# ─── Shell config ──────────────────────────────────────────────────────

color "1" "--- Shell config ($SHELL_RC) ---"
add_to_rc 'export EDITOR="nvim"'
add_to_rc 'export VISUAL="nvim"'
add_to_rc 'export PATH="$HOME/.local/bin:$PATH"'
ok "Shell config up to date"
echo ""

# ─── Symlinks & directories ───────────────────────────────────────────

color "1" "--- Symlinks & directories ---"
mkdir -p ~/.config/kitty
ln -sf ~/.config/nvim/kitty/kitty.conf ~/.config/kitty/kitty.conf
ok "Linked kitty.conf"

# kitty.conf does `include current-theme.conf`, which isn't tracked in the repo
# (it's generated per-machine). Without it, Kitty falls back to default colors.
if [ -f ~/.config/kitty/current-theme.conf ]; then
    ok "Kitty theme already generated"
elif command -v kitty &>/dev/null; then
    kitty +kitten themes --reload-in=none "Gruvbox Dark Hard" \
        && ok "Generated Kitty theme (Gruvbox Dark Hard)" \
        || warn "Could not generate Kitty theme — run: kitty +kitten themes \"Gruvbox Dark Hard\""
fi

mkdir -p ~/.config/lazygit
ln -sf ~/.config/nvim/lazygit/config.yml ~/.config/lazygit/config.yml
ok "Linked lazygit config"

mkdir -p ~/.vim/undodir
ok "Persistent undo directory ready"

if [ ! -f ~/.config/nvim/init.lua ]; then
    echo ""
    warn "Config repo not detected at ~/.config/nvim"
    info "Clone it with: git clone https://github.com/garkra/dotfiles.git ~/.config/nvim"
fi
echo ""

# ─── Summary ──────────────────────────────────────────────────────────

color "1" "=== Setup complete! ==="
echo ""
info "Next steps:"
info "  1. Restart your shell or run: source $SHELL_RC"
info "  2. Open Kitty and run 'nvim' — plugins auto-install on first launch"
info "  3. After plugins finish, restart Neovim"
info "  4. Run :Copilot setup to authenticate GitHub Copilot"
echo ""
