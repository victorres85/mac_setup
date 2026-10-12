#!/usr/bin/env bash

# ==============================================================================
# macOS Development Environment Setup Script
# Installs: Homebrew, Git, GH CLI, tmux, VS Code, Terraform, Node.js (with npx),
#           Bun, Checkov, Trivy, Docker Desktop, pgAdmin 4, pyenv, uv, AWS CLI,
#           Google Cloud SDK, htop, and iTerm2.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Text formatting helpers
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RED="\033[0;31m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*"; }

echo -e "${BOLD}=========================================="
echo " Starting macOS Environment Setup"
echo -e "==========================================${RESET}\n"

# ------------------------------------------------------------------------------
# 1. Xcode Command Line Tools (prerequisite for Homebrew & builds)
# ------------------------------------------------------------------------------
info "Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo -e "${YELLOW}Please complete the Xcode prompt on screen before continuing.${RESET}"
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    success "Xcode Command Line Tools installed."
else
    success "Xcode Command Line Tools already installed."
fi

# ------------------------------------------------------------------------------
# 2. Homebrew Installation & PATH Configuration
# ------------------------------------------------------------------------------
info "Checking Homebrew..."
if [[ "$(uname -m)" == "arm64" ]]; then
    BREW_PREFIX="/opt/homebrew"
else
    BREW_PREFIX="/usr/local"
fi

if command -v brew &>/dev/null; then
    success "Homebrew is already installed."
else
    if [[ -x "${BREW_PREFIX}/bin/brew" ]]; then
        info "Homebrew found at ${BREW_PREFIX} but not in PATH."
    else
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Configure brew path for the current session & future shells
    eval "$("${BREW_PREFIX}/bin/brew" shellenv)"

    # Add to shell profile if not present (~/.zprofile is standard for macOS zsh)
    SHELL_PROFILE="$HOME/.zprofile"
    if ! grep -q 'eval "\$('"${BREW_PREFIX}"'/bin/brew shellenv)"' "$SHELL_PROFILE" 2>/dev/null; then
        echo "eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\"" >> "$SHELL_PROFILE"
    fi
    success "Homebrew configured and added to shell configuration."
fi

info "Updating Homebrew recipes..."
brew update

# ------------------------------------------------------------------------------
# 3. CLI Formulae
# ------------------------------------------------------------------------------
# Note: HashiCorp maintains official terraform via hashicorp/tap
info "Adding HashiCorp tap for Terraform..."
brew tap hashicorp/tap --quiet || true

CLI_PACKAGES=(
    git
    gh
    tmux
    htop
    neovim               # Neovim editor (v0.10+)
    ripgrep              # Required by Telescope in nvim
    node                # Includes npm and npx
    bun
    hashicorp/tap/terraform
    checkov
    trivy
    pyenv
    uv
    awscli
)

info "Installing CLI tools..."
for pkg in "${CLI_PACKAGES[@]}"; do
    if brew list "$pkg" &>/dev/null; then
        warn "Package '$pkg' is already installed, skipping."
    else
        info "Installing '$pkg'..."
        brew install "$pkg"
    fi
done

# ------------------------------------------------------------------------------
# 4. GUI Applications & Desktop Tools (Casks)
# ------------------------------------------------------------------------------
CASKS=(
    visual-studio-code
    iterm2
    docker-desktop               # Docker Desktop
    pgadmin4
    gcloud-cli                   # gcloud CLI and components
    font-jetbrains-mono-nerd-font # Nerd Font for Neovim / terminal icons
)

info "Installing GUI applications & casks..."
for cask in "${CASKS[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
        warn "Cask '$cask' is already installed, skipping."
    else
        info "Installing '$cask'..."
        brew install --cask "$cask"
    fi
done

# ------------------------------------------------------------------------------
# 5. Shell Environment Configuration (.zshrc)
# ------------------------------------------------------------------------------
ZSHRC="$HOME/.zshrc"
info "Ensuring environment hooks are set in ${ZSHRC}..."

# Setup pyenv hook
if ! grep -q 'pyenv init' "$ZSHRC" 2>/dev/null; then
    cat << 'EOF' >> "$ZSHRC"

# Pyenv initialization
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
EOF
    info "Added pyenv initialization to ${ZSHRC}."
fi

# Setup Google Cloud SDK auto-completion and PATH
GCLOUD_PATH="$(brew --prefix)/share/google-cloud-sdk"
if [[ -d "$GCLOUD_PATH" ]] && ! grep -q 'google-cloud-sdk' "$ZSHRC" 2>/dev/null; then
    cat << EOF >> "$ZSHRC"

# Google Cloud SDK
if [ -f "${GCLOUD_PATH}/path.zsh.inc" ]; then source "${GCLOUD_PATH}/path.zsh.inc"; fi
if [ -f "${GCLOUD_PATH}/completion.zsh.inc" ]; then source "${GCLOUD_PATH}/completion.zsh.inc"; fi
EOF
    info "Added gcloud path and autocompletion to ${ZSHRC}."
fi

# Setup Aliases
if ! grep -q 'alias reload=' "$ZSHRC" 2>/dev/null; then
    cat << 'EOF' >> "$ZSHRC"

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias reload='source ~/.zshrc'
alias nvim-reload='pkill nvim && nvim'
EOF
    info "Added custom aliases to ${ZSHRC}."
fi

# Setup Color Prompt
if ! grep -q 'color_prompt=' "$ZSHRC" 2>/dev/null; then
    cat << 'EOF' >> "$ZSHRC"

# Color prompt configuration
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ "$color_prompt" = yes ]; then
    PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '
else
    PROMPT='%n@%m:%~$ '
fi
unset color_prompt
EOF
    info "Added color prompt configuration to ${ZSHRC}."
fi

# Setup Terminal Window/Tab Title
if ! grep -q 'rxvt\*)' "$ZSHRC" 2>/dev/null; then
    cat << 'EOF' >> "$ZSHRC"

# Set terminal window / tab title
case "$TERM" in
xterm*|rxvt*)
    precmd() {
        print -Pn "\e]0;%n@%m: %~\a"
    }
    ;;
*)
    ;;
esac
EOF
    info "Added terminal window/tab title configuration to ${ZSHRC}."
fi



# ------------------------------------------------------------------------------
# 6. Neovim Setup & Configuration (victorres85/nvim)
# ------------------------------------------------------------------------------
NVIM_CONFIG_DIR="$HOME/.config/nvim"
NVIM_REPO="https://github.com/victorres85/nvim.git"

info "Configuring Neovim from ${NVIM_REPO}..."
mkdir -p "$HOME/.config"

if [[ -d "$NVIM_CONFIG_DIR/.git" ]]; then
    CURRENT_REMOTE="$(git -C "$NVIM_CONFIG_DIR" remote get-url origin 2>/dev/null || true)"
    if [[ "$CURRENT_REMOTE" == *"victorres85/nvim"* ]]; then
        info "Existing victorres85/nvim configuration found. Pulling latest updates..."
        git -C "$NVIM_CONFIG_DIR" pull --ff-only || warn "Could not fast-forward pull victorres85/nvim. Check manually if you made local edits."
    else
        BACKUP_DIR="${NVIM_CONFIG_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        warn "Existing config at ${NVIM_CONFIG_DIR} is from another source. Backing up to ${BACKUP_DIR}..."
        mv "$NVIM_CONFIG_DIR" "$BACKUP_DIR"
        info "Cloning victorres85/nvim into ${NVIM_CONFIG_DIR}..."
        git clone "$NVIM_REPO" "$NVIM_CONFIG_DIR"
    fi
elif [[ -d "$NVIM_CONFIG_DIR" ]]; then
    BACKUP_DIR="${NVIM_CONFIG_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    warn "Existing non-git config directory found. Backing up to ${BACKUP_DIR}..."
    mv "$NVIM_CONFIG_DIR" "$BACKUP_DIR"
    info "Cloning victorres85/nvim into ${NVIM_CONFIG_DIR}..."
    git clone "$NVIM_REPO" "$NVIM_CONFIG_DIR"
else
    info "Cloning victorres85/nvim into ${NVIM_CONFIG_DIR}..."
    git clone "$NVIM_REPO" "$NVIM_CONFIG_DIR"
fi

# Pre-sync lazy.nvim plugins headlessly
if command -v nvim &>/dev/null; then
    info "Bootstrapping lazy.nvim plugins headlessly..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
    success "Neovim plugins synchronized."
fi

# ------------------------------------------------------------------------------
# 7. Tmux Setup & Configuration (tmux.conf & TPM)
# ------------------------------------------------------------------------------
TMUX_SOURCE="${SCRIPT_DIR}/tmux.conf"
TMUX_TARGET="$HOME/.tmux.conf"
TPM_DIR="$HOME/.tmux/plugins/tpm"

info "Setting up tmux configuration..."
if [[ -f "$TMUX_SOURCE" ]]; then
    if [[ -L "$TMUX_TARGET" ]]; then
        TARGET_LINK="$(readlink "$TMUX_TARGET" || true)"
        if [[ "$TARGET_LINK" == "$TMUX_SOURCE" ]]; then
            info "$TMUX_TARGET is already linked to $TMUX_SOURCE."
        else
            info "Updating symlink $TMUX_TARGET -> $TMUX_SOURCE..."
            ln -sf "$TMUX_SOURCE" "$TMUX_TARGET"
            success "tmux.conf symlinked to $TMUX_TARGET."
        fi
    elif [[ -f "$TMUX_TARGET" ]]; then
        BACKUP_TMUX="${TMUX_TARGET}.backup.$(date +%Y%m%d_%H%M%S)"
        warn "Backing up existing ~/.tmux.conf to ${BACKUP_TMUX}..."
        mv "$TMUX_TARGET" "$BACKUP_TMUX"
        info "Symlinking ${TMUX_SOURCE} -> ${TMUX_TARGET}..."
        ln -sf "$TMUX_SOURCE" "$TMUX_TARGET"
        success "tmux.conf symlinked to ${TMUX_TARGET}."
    else
        info "Symlinking ${TMUX_SOURCE} -> ${TMUX_TARGET}..."
        ln -sf "$TMUX_SOURCE" "$TMUX_TARGET"
        success "tmux.conf symlinked to ${TMUX_TARGET}."
    fi
else
    warn "No tmux.conf found in ${SCRIPT_DIR}."
fi

# Install Tmux Plugin Manager (TPM) required by tmux.conf
if [[ ! -d "$TPM_DIR" ]]; then
    info "Installing Tmux Plugin Manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    success "TPM installed to ${TPM_DIR}."
else
    success "TPM is already installed."
fi

# Automatically install TPM plugins headlessly if tmux is installed
if command -v tmux &>/dev/null && [[ -f "$TPM_DIR/bin/install_plugins" ]]; then
    info "Installing tmux plugins via TPM..."
    # install_plugins needs a running tmux server with the config loaded
    tmux start-server \; source-file "$TMUX_TARGET" 2>/dev/null || true
    if "$TPM_DIR/bin/install_plugins"; then
        success "tmux plugins installed."
    else
        warn "TPM plugin install failed. Open tmux and press prefix + I to install manually."
    fi
fi

# ------------------------------------------------------------------------------
# 8. Verification Summary
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}=========================================="
echo " Verifying Installed Tools"
echo -e "==========================================${RESET}"

MISSING=0

check_cmd() {
    local cmd="$1"
    local desc="$2"
    if command -v "$cmd" &>/dev/null; then
        printf "%-20s ${GREEN}✔ Available${RESET} (%s)\n" "$desc" "$cmd"
    else
        printf "%-20s ${RED}✘ Not found in PATH${RESET}\n" "$desc"
        MISSING=$((MISSING + 1))
    fi
}

check_cmd brew "Homebrew"
check_cmd git "Git"
check_cmd gh "GitHub CLI (gh)"
check_cmd tmux "tmux"
check_cmd htop "htop"
check_cmd nvim "Neovim"
check_cmd rg "ripgrep"
check_cmd code "VS Code CLI"
check_cmd terraform "Terraform"
check_cmd node "Node.js"
check_cmd npx "npx (via Node)"
check_cmd bun "Bun"
check_cmd checkov "Checkov"
check_cmd trivy "Trivy"
check_cmd pyenv "pyenv"
check_cmd uv "uv"
check_cmd aws "AWS CLI"
check_cmd gcloud "Google Cloud CLI"
check_cmd docker "Docker"

if [[ "$MISSING" -eq 0 ]]; then
    echo -e "\n${GREEN}${BOLD}Setup completed successfully!${RESET}"
else
    echo -e "\n${YELLOW}${BOLD}Setup finished, but ${MISSING} tool(s) were not found in PATH (see above).${RESET}"
fi
echo -e "${YELLOW}Note: Restart your terminal or run:${RESET} source ~/.zshrc"

