# mac_setup

One script to set up a macOS development machine: it installs my CLI tools and apps with Homebrew, configures zsh, and pulls in my Neovim and tmux configs.

## Quick start

```bash
git clone https://github.com/victorres85/mac_setup.git
cd mac_setup
./setup_mac.sh
```

When it finishes, restart the terminal or run `source ~/.zshrc`.

You can run the script more than once. It skips packages that are already installed and leaves existing `~/.zshrc` blocks alone.

## What it does

### 1. Prerequisites
- Installs the **Xcode Command Line Tools** if they are missing, then waits for you to finish the on-screen prompt.
- Installs **Homebrew** (`/opt/homebrew` on Apple Silicon, `/usr/local` on Intel) and adds `brew shellenv` to `~/.zprofile`.

### 2. CLI tools (Homebrew formulae)

| Category | Packages |
| --- | --- |
| Core | `git`, `gh`, `tmux`, `htop` |
| Editor | `neovim`, `ripgrep` (used by Telescope) |
| JavaScript | `node` (includes npm and npx), `bun` |
| Python | `pyenv`, `uv` |
| Infrastructure / security | `terraform` (from `hashicorp/tap`), `checkov`, `trivy` |
| Cloud | `awscli` |

### 3. Apps (Homebrew casks)
- Visual Studio Code
- iTerm2
- Docker Desktop
- pgAdmin 4
- Google Cloud CLI
- JetBrains Mono Nerd Font

### 4. Shell configuration (`~/.zshrc`)
Each block is added only if it isn't already in the file:
- `pyenv` initialization
- Google Cloud SDK `PATH` and completions
- Aliases: `ll`, `la`, `l`, `reload`, `nvim-reload`
- A colored `user@host:path$` prompt
- Terminal window/tab title set to the current user, host and directory

### 5. Neovim
- Clones [victorres85/nvim](https://github.com/victorres85/nvim) into `~/.config/nvim`.
- If that repo is already there, it pulls the latest changes. Any other existing config is first backed up to `~/.config/nvim.backup.<timestamp>`.
- Installs the lazy.nvim plugins headlessly.

### 6. tmux
- Symlinks this repo's `tmux.conf` to `~/.tmux.conf`. An existing file is first backed up to `~/.tmux.conf.backup.<timestamp>`.
- Installs [TPM](https://github.com/tmux-plugins/tpm) and the configured plugins.

### 7. Verification
At the end it checks that each tool is on your `PATH` and prints any that are missing.

## tmux configuration highlights

`tmux.conf` is tuned to work alongside Neovim.

| Key | Action |
| --- | --- |
| `Ctrl+Space` | Prefix (press it twice to send `Ctrl+Space` to Neovim) |
| `Ctrl+h/j/k/l` | Move between tmux panes and Neovim splits (vim-tmux-navigator) |
| `Alt+Arrows` | Switch panes |
| `Shift+Left/Right`, `Alt+Shift+H/L` | Previous/next window |
| `prefix` + `\|` / `-` | Split horizontally/vertically in the current directory |
| `prefix` + `v`, `PageUp` | Enter copy mode (vi keys: `v` select, `Ctrl+v` rectangle, `y` yank) |
| `prefix` + `r` | Reload the config |
| `prefix` + `I` | Install TPM plugins |

It also:
- Enables true color, undercurl, focus events, OSC 52 clipboard and the mouse.
- Starts window and pane numbering at 1 and renumbers windows when one closes.
- Uses a dark theme with a `#300A24` background, matching the Neovim colorscheme.
- Loads these plugins: tmux-sensible, vim-tmux-navigator, tmux-yank, tmux-resurrect, tmux-prefix-highlight.

## Customizing

- **Packages:** edit the `CLI_PACKAGES` and `CASKS` arrays in `setup_mac.sh`.
- **Prefix key:** to use `Ctrl+a` instead of `Ctrl+Space`, uncomment the alternative lines in section 2 of `tmux.conf`.
- **Neovim config:** change `NVIM_REPO` in `setup_mac.sh` to point to your own repo.

## Requirements

- macOS on Apple Silicon or Intel
- An admin account, which the Homebrew installer needs
- An internet connection
