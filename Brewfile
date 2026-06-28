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
brew 'jq'                         # JSON processor for the shell
brew 'watch'                      # Run a command periodically, fullscreen
brew 'wget'                       # Simple HTTP client (prefer curl when possible)
brew 'bat'                        # cat with syntax highlighting

# VCS
brew 'pre-commit'                 # Pre-commit hook framework

# Shell / dev tooling
brew 'antigen'                    # zsh plugin manager (slated for sheldon in dotfiles-f0w)
brew 'cmake'                      # Build tool (also needed by some Rust/ESP builds)
brew 'direnv'                     # Per-directory environment loading
brew 'libyaml'                    # Should come after openssl

# JavaScript / TypeScript
brew 'nodenv'                     # Manage multiple node versions
brew 'pnpm'                       # Fast npm alternative

# Java / JVM — commented out until JVM work resumes (java currently unprovisioned).
# Re-add together with a JDK (e.g. brew 'openjdk') when needed.
# brew 'gradle'                   # JVM build tool (Android, Jenkins tooling)
# brew 'maven'                    # JVM build/dependency tool

# Python
brew 'poetry'                     # Python packaging / dependency management
brew 'pyenv'                      # Manage multiple python versions
brew 'pyenv-virtualenv'           # Virtualenv support for pyenv

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
