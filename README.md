# dotfiles

Personal macOS + WSL2 dotfiles, managed by [chezmoi](https://www.chezmoi.io/) with an
XDG-first layout (`~/.config`, `~/.local/state`, `~/.cache`). Machine and identity
differences are handled with chezmoi templates + [1Password](https://1password.com/)
secrets — not per-machine shadow files.

The chezmoi **source state** lives in this repo; `chezmoi apply` renders it into `$HOME`.

> Architecture, layout conventions, and per-tool notes live in [CLAUDE.md](CLAUDE.md).
> This README is the human getting-started + day-to-day guide.

## Set up a fresh machine

Prerequisite: install the [1Password desktop app](https://1password.com/downloads/),
sign in, and enable **Settings → Developer → CLI integration** and the **SSH agent**.
Secrets and commit signing are read from 1Password at apply time.

One-shot bootstrap (installs Homebrew + chezmoi, applies the dotfiles, sets zsh as the
login shell):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/jeckhart/dotfiles/main/script/setup)"
```

Or, if Homebrew + chezmoi are already present, do it manually:

```bash
chezmoi init --apply jeckhart/dotfiles
```

At first `chezmoi init` you'll be asked for the **1Password vault** that holds the dotfiles
secrets (answer it so `op://…` templates render). WSL2 is auto-detected from `/proc/version`;
Apple Silicon from the arch — no manual flags.

## Stay up to date

Pull the latest source and re-render in one step:

```bash
chezmoi update       # = git pull in the source repo + chezmoi apply
```

Prefer to see what will change first (recommended):

```bash
cd $(chezmoi source-path)
git pull --rebase          # fetch newer commits from the other machine
chezmoi diff               # preview target changes on THIS machine
chezmoi apply              # apply them
```

`chezmoi apply` re-runs the `run_onchange_*` scripts when their inputs change — e.g. it
runs `brew bundle` whenever `Brewfile` changed, and `mise install` when the mise config
changed. 1Password will prompt for Touch ID the first time a secret is read.

## Make and publish a change

Edit the **source**, test locally, then commit and push so other machines can pull it:

```bash
chezmoi edit ~/.config/zsh/configs/foo.zsh   # opens the source file for that target
# ...or work directly in the source tree:
chezmoi cd                                    # cd into the source repo

chezmoi diff && chezmoi apply                 # verify it renders/applies as intended

git add -A && git commit -m "…" && git push   # publish (commits are SSH-signed via 1Password)
```

The typical multi-machine loop is: change + push on machine A → `chezmoi update` on
machine B. Because config is templated by `.isWSL2` / `.isAppleSilicon`, the same source
renders correctly on both macOS and WSL2.

## Secrets & per-machine differences

- **Secrets** come from 1Password via templates and are never committed. To add one, create a
  `dot_config/zsh/configs/<name>.zsh.tmpl` containing
  `export TOKEN={{ onepasswordRead "op://<vault>/<item>/<field>" }}`; `chezmoi apply` bakes
  the value into the (gitignored) rendered file.
- **Machine/identity differences** use template conditionals (`.isWSL2`, `.isAppleSilicon`,
  `.chezmoi.os`) and 1Password — there are no `.local` / `.donotcommit` shadow files.
- **Commit signing** is SSH-based via the 1Password agent; each identity has its own
  ed25519 key in 1Password. See CLAUDE.md → *Git Identity* and *Secrets*.

## Adding tools & dependencies

- New tool config → add a `.zsh` file under `dot_config/zsh/configs/` (loads automatically;
  use `pre/` or `post/` for ordering).
- New dotfile → `chezmoi add ~/.foo`, then `chezmoi apply`.
- New Homebrew package → add it to `Brewfile` (next `chezmoi apply` runs `brew bundle`).

## Developing these dotfiles (lint & format)

This repo lints and formats itself with [`hk`](https://hk.jdx.dev) (jdx's git-hook manager).
The toolchain is pinned in `mise.toml` (repo-root, not deployed) and is all native — no node.
One-time setup per clone:

```bash
cd $(chezmoi source-path)
mise install     # installs hk + linters (shellcheck, shfmt, taplo, stylua, dprint, pkl)
mise run setup   # = hk install — wires the pre-commit hook into THIS repo's .git
```

Then it runs automatically on `git commit` (formats staged files, blocks on lint errors).
Run it manually anytime:

```bash
hk check         # lint/format-check staged files (read-only)
hk check --all   # …across the whole repo
hk fix           # apply formatters to staged files
hk fix --all     # …across the whole repo (one-time baseline reformat)
```

Coverage: shellcheck + shfmt (shell), taplo (TOML), stylua (Lua), `dprint` (Markdown/JSON/YAML,
config in `dprint.json`), pkl (the `hk.pkl` config itself). chezmoi `*.tmpl` files are excluded
automatically (extension globs never match `*.sh.tmpl` etc.); generated files (`lazy-lock.json`)
and vendored content (`.agents/`, `.beads/`) are excluded in `dprint.json`.
