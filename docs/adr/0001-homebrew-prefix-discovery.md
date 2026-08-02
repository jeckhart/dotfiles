# ADR 0001: Never derive the Homebrew prefix from OS/arch — probe for `brew`

Status: Accepted

## Context

A fresh WSL2 Ubuntu bootstrap (`bash -c "$(curl … script/setup)"`) failed:

```text
/home/linuxbrew/.linuxbrew/bin/brew          ← what the installer actually created
bash: line 32: /usr/local/bin/brew: No such file or directory
bash: line 36: brew: command not found
```

`script/setup` picked the Homebrew prefix from `uname -m`:

```sh
if [ "$UNAME_MACHINE" = "arm64" ]; then HOMEBREW_PREFIX="/opt/homebrew"
else                                    HOMEBREW_PREFIX="/usr/local"; fi
```

`arm64` is a macOS-only arch token — Linux reports `x86_64`/`aarch64` — so every Linux
host fell into the `else` branch and got `/usr/local`, a directory Linuxbrew never
touches. `set -e` didn't catch it either: `eval "$(.../brew shellenv)"` takes `eval`'s
exit status (0 for an empty string), swallowing the 127 from the failed command
substitution.

Auditing the repo turned up **four real prefixes** across the fleet — `/opt/homebrew`
(Apple Silicon), `/usr/local` (Intel Mac), `/home/linuxbrew/.linuxbrew` (WSL2/Linux), and
a nix-homebrew work machine where `HOMEBREW_REPOSITORY` points into `/nix/store` — and
**three different strategies already coexisting** for picking one:

| Strategy                                                                                 | Verdict                                                                                                      |
| ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Runtime probe ladder incl. Linuxbrew (`dot_zprofile.tmpl`, `pre/brew.zsh`, `beads-dolt-server.sh`) | correct everywhere                                                                                  |
| Runtime probe, macOS prefixes only (`local.beads.dolt.plist.tmpl`'s LaunchAgent `PATH`)  | correct *only* because darwin-gated by `.chezmoiignore`                                                      |
| Template-time arch/`.isAppleSilicon` guess (`script/setup`, `radicle-node-wrapper.tmpl`) | **wrong on Linux** — the wrapper survived by being darwin-gated too; `script/setup` wasn't gated by anything |

`.chezmoi.toml.tmpl` exposes `isWSL2` / `isAppleSilicon` / `opVault` but no brew prefix, so
every consumer re-derives it from scratch — which is how the same bug gets reintroduced
each time a new one is written.

## Decision

**Never infer the Homebrew prefix from `.chezmoi.os`, `.chezmoi.arch`, or
`.isAppleSilicon`. Always probe for an actual `brew` binary**, in this order: `$PATH`
(`command -v brew` / template `lookPath "brew"`), then `$HOMEBREW_PREFIX` if already set,
then the three known install roots (`/opt/homebrew`, `/usr/local`,
`/home/linuxbrew/.linuxbrew`). First hit wins; no hit means brew isn't installed yet, and
callers get an empty string, not a guess.

One canonical implementation, two forms:

- **`.chezmoitemplates/brew/prefix`** — render-time resolution for templates that need to
  bake a literal path into a rendered file (a LaunchAgent's `PATH`, a wrapper script's
  brew root). Uses `lookPath` + `stat`.
- **`.chezmoitemplates/brew/shellenv`** — the POSIX-sh ladder as text, for scripts that
  need brew on `PATH` at run time. `{{ includeTemplate "brew/shellenv" . }}`.

`script/setup` is the one exception that can't use either: it runs via `curl | bash`
before the source repo exists, so it inlines the same ladder by hand. Its copy is the
one place this rule has to be kept in sync manually — comment it points back here.

## Consequences

- One candidate list to update if a fifth prefix ever shows up (e.g. a future package
  manager change) — edit `brew/prefix` and `brew/shellenv`, `script/setup`'s inline copy,
  and this ADR.
- A brew-less host renders an empty prefix rather than a wrong one. Every caller keeps
  its own runtime guard (`-x`, `-e`, `command -v`) rather than trusting the string is
  populated — an unguarded empty-prefix path silently swallowed into `fpath` is exactly
  the kind of bug this ADR exists to prevent (fixed alongside this ADR in
  `dot_config/zsh/configs/post/completion.zsh`).
- `run_onchange_*` scripts that `command -v <tool> || exit 0` (mise, bat, yazi, the
  Brewfile itself) now source `brew/shellenv` first and print a warning before skipping,
  instead of silently no-op'ing on a host where brew exists but isn't on `chezmoi apply`'s
  PATH.
- `beads-dolt-server.sh`'s own `dolt` lookup stays a hand-rolled probe, not switched to
  the `brew/prefix` partial: it intentionally checks *every* known prefix rather than
  resolving to one (a machine can carry a native `/opt/homebrew` Apple Silicon install
  alongside a Rosetta `/usr/local` one, and the caller wants whichever has the `dolt`
  formula), and now that the wrapper also runs on WSL2 its ladder includes
  `/home/linuxbrew/.linuxbrew` too — the whole point being a runtime probe, not an
  apply-time guess, so it works unmodified regardless of which host applies it.
- `local.beads.dolt.plist.tmpl`'s LaunchAgent `PATH` is the one exception still staying
  hardcoded to the two macOS prefixes rather than the partial, for the same "want
  whichever has git" reason above. It's gated to `.chezmoi.os == "darwin"` by
  `.chezmoiignore`, so the Linux case this ADR is about never reaches it — the sibling
  systemd unit (`beads-dolt.service.tmpl`) uses `brew/prefix` instead, since a template's
  `PATH` only needs one working prefix, not "whichever of two."
- `Brewfile`'s `unless system "[ -e /usr/local/bin/aws ]"` also stays: it detects the AWS
  CLI's own pkg installer (always `/usr/local/bin` regardless of arch), not a Homebrew
  prefix, so this rule doesn't apply to it.
