# Homebrew dependencies for these dotfiles. Installed by
# run_onchange_install-packages.sh.tmpl (re-runs when this file changes).

tap 'homebrew/bundle'

# Early requirements
brew 'openssl'                    # Recent openssl other formulae depend on

# Dotfiles / config management
brew 'chezmoi'                    # Manage personal configuration files across machines
brew 'socat'                      # Used in WSL2 to bridge the ssh-agent from Windows

# Unix / search
brew 'ripgrep'                    # Fast grep replacement
brew 'tmux'                       # Persistent terminal sessions
brew 'fzf'                        # Command-line fuzzy finder
brew 'fd'                         # Fast, friendly find (powers fzf default command)
brew 'jq'                         # JSON processor for the shell
brew 'watch'                      # Run a command periodically, fullscreen
brew 'wget'                       # Simple HTTP client (prefer curl when possible)
brew 'bat'                        # cat with syntax highlighting (also feeds delta + yazi preview)

# Modern shell UX (framework-free zsh stack — see dot_config/zsh + sheldon)
brew 'sheldon'                    # zsh plugin manager (TOML, replaces antigen)
brew 'starship'                   # Prompt (configured in dot_config/starship.toml)
brew 'zoxide'                     # Frecency directory jumper (z / zi)
brew 'atuin'                      # Shell history database + Ctrl-R search
brew 'eza'                        # Modern ls replacement (icons, git, tree)
brew 'vivid'                      # Generates the Catppuccin Macchiato LS_COLORS (themes ls/eza/completions)
brew 'yazi'                       # Terminal file manager
brew 'duckdb'                     # In-process SQL OLAP DB — backs yazi's duckdb.yazi data preview (CSV/TSV/JSON/Parquet)
brew 'git-delta'                  # Syntax-highlighting git pager

# GNU userland (gnubin-first PATH in configs/gnu.zsh: sed/date/grep use GNU under normal names)
brew 'coreutils'
brew 'findutils'
brew 'gnu-sed'
brew 'gnu-tar'
brew 'grep'
brew 'gawk'

# VCS
brew 'pre-commit'                 # Pre-commit hook framework

# Shell / dev tooling
brew 'cmake'                      # Build tool (also needed by some Rust/ESP builds)
brew 'direnv'                     # Per-directory environment loading
brew 'libyaml'                    # Should come after openssl

# Language runtimes — mise manages node, python, etc. (replaces nodenv + pyenv).
# Pins + settings: dot_config/mise/config.toml; activation: configs/mise.zsh.
brew 'mise'                       # Fast polyglot runtime/version manager (Rust)

# JavaScript / TypeScript
brew 'pnpm'                       # Fast npm alternative (standalone; not managed by mise)

# Java / JVM — commented out until JVM work resumes (java currently unprovisioned).
# Re-add together with a JDK (e.g. brew 'openjdk') when needed.
# brew 'gradle'                   # JVM build tool (Android, Jenkins tooling)
# brew 'maven'                    # JVM build/dependency tool

# Python (runtimes via mise above; uv for venvs/packaging)
brew 'uv'                         # Fast Python package + venv manager (replaces pyenv-virtualenv)
brew 'poetry'                     # Python packaging — legacy projects; migrating to uv

# Go
brew 'go'                         # Go toolchain

# Rust — the toolchain itself comes from rustup (stable + esp-nightly), not brew.
# These are standalone cargo helper binaries.
brew 'cargo-deny'
brew 'cargo-generate'
brew 'cargo-make'
brew 'cargo-nextest'

# DevOps
brew 'awscli' unless system "[ -e /usr/local/bin/aws ]" # AWS CLI
brew 'kubernetes-cli'             # kubectl (zsh kubectl plugin expects it)
brew 'opentofu'                   # Terraform-compatible IaC

# Security / secrets
cask '1password'                  # Desktop app: SSH agent + op-ssh-sign for commit signing
cask '1password-cli'              # op CLI for chezmoi secret templates

# Editors
brew 'neovim'                     # LazyVim-based editor
brew 'lazygit'                    # Terminal git UI (LazyVim <leader>gg)
cask 'iterm2' unless system "[ -e /Applications/iTerm.app ]" # Terminal

# Fonts
cask 'font-meslo-lg-nerd-font'    # Nerd font used by starship / powerlevel10k
