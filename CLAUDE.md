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


<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:6cd5cc61 -->
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

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->
