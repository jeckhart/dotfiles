# CLAUDE.md

## Overview

Personal dotfiles for macOS, managed by [chezmoi](https://www.chezmoi.io/) with an
XDG-first layout (`~/.config`, `~/.local/state`, `~/.cache`). The chezmoi source state
lives in this repo; machine and identity differences are handled with templates + 1Password
rather than per-file overrides. (Historically these dotfiles layered the
[thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles) submodule managed by
[rcm](https://github.com/thoughtbot/rcm) — both have been retired.)

## Setup & Installation

Day-to-day, chezmoi owns the dotfiles:

```bash
chezmoi diff           # Preview pending changes
chezmoi apply          # Apply source changes to $HOME
chezmoi edit <file>    # Edit a managed file's source
chezmoi cd             # Open the source repo
```

New-machine bootstrap is `script/setup` (being migrated to `chezmoi init --apply`,
tracked in dotfiles-06f). On a fresh machine, answer the 1Password vault prompt at
`chezmoi init` so `op:///...` templates render.

## Architecture

### Dotfile Management (chezmoi)

Source-state files map to `$HOME` by chezmoi naming: `dot_` → `.`, `executable_` → adds
+x, `*.tmpl` → templated, `private_` → 0600. Examples:

```
dot_zshenv                       -> ~/.zshenv
dot_config/git/config            -> ~/.config/git/config
dot_bin/executable_clear-port    -> ~/.bin/clear-port   (executable)
```

`.chezmoiignore` lists repo meta-files (README, Brewfile, `script/`, `.beads`) that are
not deployed. Identity/machine differences use templates + 1Password (`onepasswordRead`),
not `*.local` shadow files.

### Zsh Configuration (XDG, ZDOTDIR)

`~/.zshenv` sets the XDG base dirs and `ZDOTDIR=~/.config/zsh`, redirecting all zsh
startup there:

1. `~/.config/zsh/.zprofile` — Homebrew init (Intel + Apple Silicon); 1Password SSH agent socket
2. `~/.config/zsh/.zshrc` — loader; sources `configs/pre/*.zsh`, then `configs/*.zsh`, then `configs/post/*.zsh`
3. `configs/antigen.zsh` — zsh plugins via Antigen (oh-my-zsh, vi-mode, direnv, fzf)

There is no `.zshrc.local` seam: we own the primary templates, so machine-generic config
lives in `configs/` and secrets come from 1Password (see Secrets). Add a `.local` shadow
file back only if a genuine machine-specific, non-secret override ever needs one.

### Git Identity

`~/.config/git/config` pulls in `config.local` plus conditional identity includes by
project directory:

- `~/projects/work/**`, `~/projects/lsp/**` → work identity (Courier Health)
- `~/projects/personal/**` → personal
- `~/projects/vela/**` → vela

All commits are SSH-signed via the 1Password SSH agent (`op-ssh-sign`). Each identity has
its own ed25519 signing key in 1Password (`Private` vault: `git-signing-personal`,
`git-signing-work`, `git-signing-vela`). Public keys are read at `chezmoi apply` via
`onepasswordRead`; `SSH_AUTH_SOCK` points at the 1Password agent (set in `.zprofile`).

### Secrets

Secrets come from 1Password via chezmoi templates — never committed, never in a
`.donotcommit`/`.local` file (that thoughtbot-era escape hatch is retired). To add a secret
env var, create a template under `dot_config/zsh/configs/` (it's machine-generic — the value
is the same on every machine because it's pulled from the vault):

```
# dot_config/zsh/configs/<name>.zsh.tmpl
export SOME_TOKEN={{ onepasswordRead "op://Private/<item>/<field>" }}
```

`chezmoi apply` bakes the value into the rendered file at `~/.config/zsh/configs/<name>.zsh`
(gitignored target, not in the repo). Auth is biometric (Touch ID via the 1Password desktop
app); `chezmoi.toml` sets `[onepassword] command = "op"`, `prompt = false`.

### Key Tool Configurations

| Tool | Source | Notes |
|------|--------|-------|
| Helix | `dot_config/helix/config.toml` | Catppuccin Mocha, vi keybindings |
| Tmux | `dot_config/tmux/tmux.conf` | Prefix `Ctrl-Space`, vi keys, Catppuccin Mocha |
| Starship | `dot_config/starship.toml` | Catppuccin Macchiato palette |
| Neovim | _migration in progress (dotfiles-pip)_ | still legacy `~/.config/nvim` until then |

### Embedded Rust / ESP32 Development

`dot_config/zsh/configs/export-esp.zsh` and `dot_bin/executable_rustrover-esp.sh`
configure the ESP-IDF toolchain. `dot_bin/executable_monitor-serial.sh` connects to USB
serial devices (auto-reconnects) for ESP32 debugging.

### Homebrew Dependencies

Tracked in `Brewfile`. Notable: chezmoi, 1password-cli, fzf, starship, antigen, neovim,
awscli, opentofu. (Language managers: nodenv, pyenv, rbenv, rustup.)

## Adding New Configurations

- Add a `.zsh` file under `dot_config/zsh/configs/` for a new tool (loads automatically);
  use `pre/` or `post/` for ordering relative to plugin init and PATH finalization.
- Add new dotfiles to the chezmoi source with the right prefix (`chezmoi add ~/.foo`),
  then `chezmoi apply`.
- Update `Brewfile` when adding Homebrew dependencies.


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
