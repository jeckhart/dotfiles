# Homebrew dependencies for these dotfiles. Installed by
# run_onchange_install-packages.sh.tmpl (re-runs when this file changes).

# Taps
tap 'can1357/tap'                 # omp (listed here so `brew bundle cleanup` keeps the tap)

# Early requirements
brew 'openssl'                    # Recent openssl other formulae depend on

# Dotfiles / config management
brew 'chezmoi'                    # Manage personal configuration files across machines

# Unix / search
brew 'ripgrep'                    # Fast grep replacement
brew 'tmux'                       # Persistent terminal sessions
brew 'fzf'                        # Command-line fuzzy finder
brew 'fd'                         # Fast, friendly find (powers fzf default command)
brew 'jq'                         # JSON processor for the shell
brew 'yq'                         # jq for YAML
brew 'watch'                      # Run a command periodically, fullscreen
brew 'hwatch'                     # watch with history + diff highlighting (aliased over watch)
brew 'wget'                       # Simple HTTP client (prefer curl when possible)
brew 'bat'                        # cat with syntax highlighting (also feeds delta + yazi preview)
brew 'bat-extras'                 # batdiff, batman, batgrep, batwatch
brew 'dust'                       # du with a usable output
brew 'entr'                       # Run a command when watched files change
brew 'qsv'                        # Fast CSV toolkit
brew 'csvlens'                    # CSV pager/viewer
brew 'pandoc'                     # Universal document converter

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
brew 'hunk'                       # Review-first terminal diff viewer for agent-authored changesets
brew 'herdr'                      # Agent multiplexer that lives in your terminal

# Peer-to-peer code collaboration (private mesh over Tailscale — see docs/radicle.md)
brew 'radicle' if OS.mac?         # rad CLI + radicle-node + git-remote-rad (WSL2: signed apt repo instead, see run_onchange_install-radicle-apt)
cask 'tailscale-app' unless system "[ -e /Applications/Tailscale.app ]" # Mesh VPN the radicle nodes ride on (GUI app; login is manual)

# GNU userland (gnubin-first PATH in configs/gnu.zsh: sed/date/grep use GNU under normal names)
brew 'coreutils'
brew 'findutils'
brew 'gnu-sed'
brew 'gnu-tar'
brew 'grep'
brew 'gawk'

# Shell / dev tooling
brew 'cmake'                      # Build tool (also needed by some Rust/ESP builds)
brew 'direnv'                     # Per-directory environment loading
# nix-direnv has no brew formula — nix machines provide it via their nix
# profile; dot_config/direnv/direnvrc sources it from there when present.
brew 'libyaml'                    # Should come after openssl
brew 'gh'                         # GitHub CLI
brew 'just'                       # Command runner (per-repo justfiles)
brew 'can1357/tap/omp'            # omp CLI (can1357's tap)

# Repo dev tooling — pre-commit hooks for this repo (hk.pkl), also pinned in
# mise.toml for project-scoped installs; listed here too as a global fallback.
brew 'hk'                         # Git hook / pre-commit lint manager (jdx)
brew 'dprint'                     # Markdown/JSON/YAML formatter driven by hk.pkl
brew 'pkl'                        # Config language used to write/format hk.pkl itself

# Issue tracking (bd) + its backing store
brew 'beads'                      # Git-backed issue tracker (bd)
brew 'dolt'                       # Versioned SQL DB backing beads

# Language runtimes — mise manages node, python, etc. (replaces nodenv + pyenv).
# Pins + settings: dot_config/mise/config.toml; activation: configs/mise.zsh.
brew 'mise'                       # Fast polyglot runtime/version manager (Rust)

# JavaScript / TypeScript
brew 'pnpm'                       # Fast npm alternative (standalone; not managed by mise)
brew 'cloudflare-wrangler'        # Cloudflare Workers CLI

# Java / JVM — commented out until JVM work resumes (java currently unprovisioned).
# Re-add together with a JDK (e.g. brew 'openjdk') when needed.
# brew 'gradle'                   # JVM build tool (Android, Jenkins tooling)
# brew 'maven'                    # JVM build/dependency tool

# Python (runtimes via mise above; uv for venvs/packaging)
brew 'uv'                         # Fast Python package + venv manager (replaces pyenv-virtualenv)
brew 'poetry'                     # Python packaging — legacy projects; migrating to uv

# Go
brew 'go'                         # Go toolchain

# Rust — the toolchain itself comes from rustup (stable + esp-nightly).
# brew's rustup provides the rustup binary; toolchains still live in ~/.rustup.
brew 'rustup'
brew 'cargo-deny'
brew 'cargo-generate'
brew 'cargo-make'
brew 'cargo-nextest'

# Embedded / ESP32 (toolchain env: configs/export-esp.zsh; serial: dot_bin/monitor-serial.sh)
brew 'espflash'                   # Flash + monitor ESP32 boards over serial

# DevOps
brew 'awscli' unless system "[ -e /usr/local/bin/aws ]" # AWS CLI
brew 'kubernetes-cli'             # kubectl (zsh kubectl plugin expects it)
brew 'opentofu'                   # Terraform-compatible IaC

# Security / secrets
brew 'pam-reattach' if OS.mac?    # Touch ID for sudo inside tmux (used by run_once_configure-touchid-sudo); no Linux bottle
cask '1password' unless system "[ -e /Applications/1Password.app ]" # Desktop app: SSH agent + op-ssh-sign for commit signing
# On WSL2 we use the Windows op.exe/op-ssh-sign.exe (via WSL interop) instead —
# see dot_config/zsh/configs/wsl2.zsh — so skip installing a redundant Linux op.
cask '1password-cli' unless system "grep -qi microsoft /proc/version 2>/dev/null"

# Editors
brew 'neovim'                     # LazyVim-based editor
brew 'lazygit'                    # Terminal git UI (LazyVim <leader>gg)
cask 'iterm2' unless system "[ -e /Applications/iTerm.app ]" # Terminal
cask 'cursor' unless system "[ -e /Applications/Cursor.app ]" # AI editor
cask 'cursor-cli'                 # cursor-agent CLI

# Fonts
cask 'font-meslo-lg-nerd-font'    # Nerd font used by starship / powerlevel10k
cask 'font-fira-code-nerd-font'
cask 'font-jetbrains-mono-nerd-font'
cask 'font-iosevka-nerd-font'
cask 'font-symbols-only-nerd-font' # Fallback glyphs for apps using a non-nerd primary font
