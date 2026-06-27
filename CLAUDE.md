# CLAUDE.md

## Overview

This is a personal dotfiles repository for macOS that layers custom configurations on top of the [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles) submodule. Dotfile symlinking is managed by [rcm](https://github.com/thoughtbot/rcm).

## Setup & Installation

```bash
./script/setup   # Full setup: install Homebrew deps, init submodules, symlink dotfiles, set default shell
./script/bootstrap  # Only install Homebrew dependencies from Brewfile
```

After cloning, run `script/setup`. To re-link dotfiles after adding new files:

```bash
rcup -v          # Re-run rcm to update symlinks
```

## Architecture

### Dotfile Management (rcm)

`rcrc` controls which directories rcm searches and what to exclude:

```
DOTFILES_DIRS="$HOME/.dotfiles $HOME/.dotfiles/thoughtbot-dotfiles"
```

Files in both directories get symlinked into `$HOME`. Local overrides take precedence over the thoughtbot submodule. Files named `*.local` (e.g., `gitconfig.local`, `zshrc.local`) are the primary extension points for personal customization.

### Zsh Configuration Loading Order

1. `zprofile` — Homebrew initialization (supports Intel and Apple Silicon paths)
2. thoughtbot's `zshrc` — sets up the plugin framework
3. `zsh/configs/pre/*.zsh` — runs before most initialization
4. `antigenrc` — loads zsh plugins via Antigen (oh-my-zsh, vi-mode, direnv, fzf, etc.)
5. `zsh/configs/*.zsh` — individual feature configs (one file per tool/concern)
6. `zsh/configs/post/*.zsh` — runs last (PATH finalization, completions)
7. `zshrc.local` — final local overrides

### Git Identity

`gitconfig.local` uses conditional includes to switch git identity by project directory:

- `~/projects/work/**`, `~/projects/lsp/**`, etc. → `gitconfig.work` (Courier Health work identity)
- `~/projects/personal/**` → `gitconfig.personal`
- `~/projects/vela/**` → `gitconfig.vela`

All commits are SSH-signed via the 1Password SSH agent (`op-ssh-sign`). Each identity has its own ed25519 signing key stored in 1Password (`Private` vault: `git-signing-personal`, `git-signing-work`, `git-signing-vela`). Public keys are read at `chezmoi apply` time via `onepasswordRead`. The `SSH_AUTH_SOCK` is set in `zprofile` to point at the 1Password agent socket.

### Key Tool Configurations

| Tool | Config Location | Notes |
|------|----------------|-------|
| Helix | `config/helix/config.toml` | Catppuccin Mocha theme, vi keybindings |
| Tmux | `config/tmux/tmux.conf` | Prefix: `Ctrl-Space`, vi keys, Catppuccin Mocha |
| Starship | `config/starship.toml` | Catppuccin Macchiato palette |
| Neovim | `vim/` (symlinked as `config/nvim`) | |

### Embedded Rust / ESP32 Development

`zsh/configs/export-esp.zsh` and `bin/rustrover-esp.sh` configure the ESP-IDF toolchain. `bin/monitor-serial.sh` connects to USB serial devices (auto-reconnects) for ESP32 debugging.

### Homebrew Dependencies

All dependencies are tracked in `Brewfile`. Notable categories:
- **Language managers**: asdf, nodenv, pyenv, rbenv, rustup
- **Shell**: antigen, fzf, starship
- **Editors**: neovim
- **DevOps**: awscli, opentofu, kops

## Adding New Configurations

- Add a new `.zsh` file to `zsh/configs/` for a new tool (it loads automatically)
- Use `zsh/configs/pre/` if it must run before plugin initialization
- Use `zsh/configs/post/` if it must run after PATH is finalized
- Add new dotfiles directly to this repo; rcm will symlink them on the next `rcup`
- Update `Brewfile` when adding new Homebrew dependencies


<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ca08a54f -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->
