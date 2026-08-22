# ADR 0004: Generate shell completions at apply time, never at shell startup

Status: Accepted

## Context

The ask was oh-my-zsh-style "completions just work" for everything installed via Homebrew
and mise, without giving back the ~490ms won by replacing nodenv/pyenv with mise (0.673s
→ 0.184s average startup — see the historical rationale in `configs/mise.zsh`).

Measuring `compinit` on this machine (`zsh/datetime` around each call) settled the design:

| | cost |
|---|---|
| `compinit -C` with the dump present | 12–15ms |
| `compinit -C` with the dump missing (rebuilds it) | ~450–500ms |
| full `compinit` (fpath rescan + `compaudit`) | ~430ms |
| `compaudit` alone | ~19ms |
| +45 extra `_foo` functions added to `fpath` | no measurable change |

Two conclusions follow directly: static completion functions are free — `autoload` is
lazy and `compinit -C` reads one pre-digested dump rather than scanning `fpath` — so
piling on more `_foo` files costs nothing. What costs real time is a subprocess:
`eval "$(tool completion zsh)"` at startup is one fork+exec per tool, and the pattern
oh-my-zsh popularized (source N such lines) is exactly the ~15 tools' worth of forks that
would erase the mise win.

Auditing what was already in place found two more defects, not just a gap to fill:

- `fpath` was growing without bound. `brew shellenv` (`.chezmoitemplates/brew/shellenv`)
  exports `FPATH`, so a nested shell inherits the parent's fully-built `fpath`, and
  `completion.zsh` prepended its three dirs unconditionally on every source — every entry
  doubled per level of shell nesting.
- The completion dump only rebuilt on a 24h timer (`compinit -d` vs `compinit -C` gated on
  `${_zcompdump}(#qN.mh+24)`), so a freshly generated completion could be invisible for up
  to a day, and the 430ms full rescan ran once daily whether or not anything had actually
  changed.
- `zoxide init zsh`'s own `compdef` is guarded by `[[ "${+functions[compdef]}" -ne 0 ]]`,
  but `configs/zoxide.zsh` loaded in the top-level pass, before `post/completion.zsh` had
  run `compinit` — the guard silently no-op'd and `z <TAB>` had no completion at all.

## Decision

**Generate every non-native completion at `chezmoi apply` time and write it to disk;
nothing forks a completion subprocess at shell startup.**

- `dot_bin/executable_regen-zsh-completions` harvests completions two ways: an explicit
  `tool → verb` table for tools whose generator verb isn't uniform (`completion zsh`,
  `completions zsh`, `--completions zsh` all appear in the wild — gitleaks, lazygit,
  pinact, taplo, rumdl, zizmor, and `rustup completions zsh cargo`, which is cargo's own
  completion despite being invoked via `rustup`), and file harvesting for tools that ship
  a finished `#compdef` file instead of a generator (helix's
  `contrib/completion/hx.zsh`). Every entry is guarded: a missing tool or a failed/empty
  generation is skipped and logged, never a hard failure — most of the gap tools are
  repo-scoped mise dev tools (pinned in the gitignored `mise.toml`) not on `PATH` outside
  this repo, and that's expected, not an error.
- `run_onchange_after_generate-completions.sh.tmpl` is the trigger, hash-keyed on the
  Brewfile, the mise lockfile, and the generator script itself — the same idiom as
  `run_onchange_after_install-mise-tools.sh.tmpl`/`build-bat-cache.sh.tmpl`. It deletes
  `zcompdump` when it runs, so the next shell picks up new completions immediately.
- **`carapace`** (`Brewfile`) covers the long tail with no per-tool table entry (`deno`,
  cargo subcommands, ~1000 other CLIs) — but strictly as a fallback. Its init is *also*
  pre-generated (`carapace _carapace zsh` → `carapace-init.zsh`, ~4ms to `source`, verified
  — vs. forking `carapace` itself at every startup). Its init unconditionally `compdef`s
  every command it recognizes, which includes several we already generate natively
  (gitleaks, lazygit, cargo, hx). `configs/post/zzz_carapace.zsh` snapshots `_comps`
  before sourcing it and restores every pre-existing mapping after, so carapace only ever
  fills a gap — it can never win over a native completer.
- `post/completion.zsh` always runs `compinit -C` (never the 24h-gated full rescan) and
  gets `typeset -gU fpath FPATH` to dedupe. A missing/stale dump self-heals on the very
  next shell (the one-time ~450–500ms cost measured above) instead of a periodic tax paid
  regardless of whether anything changed.
- `configs/zoxide.zsh` moved to `configs/post/zoxide.zsh`, after `compinit` — fixes the
  dead `z` completion as a side effect of the reordering, not a separate change.

## Consequences

- Adding a new completion means one line in `regen-zsh-completions`'s table (or a
  `harvest` call), not a new startup `eval`. The temptation to reach for
  `eval "$(tool completion zsh)"` in a `configs/*.zsh` file should be resisted — it's the
  exact cost this ADR exists to avoid; use the generator instead.
- carapace's compdef list is regenerated wholesale on every `chezmoi apply`, so as new
  tools gain native completions (ours or upstream) the fallback automatically steps aside
  next time completions regenerate — no bookkeeping to keep the two lists in sync by hand.
- `${XDG_DATA_HOME}/zsh/completions/` and `carapace-init.zsh` are wholly owned by
  `regen-zsh-completions` (wiped and rewritten each run) — never hand-edit files there;
  changes belong in the generator or in `zsh/completion/` (the hand-written functions
  directory, unaffected by this ADR).
- A completion that regresses (wrong binding, `_comps` clobbered) is diagnosable with
  `zsh -i -c 'print $_comps[<cmd>]'` — see the verification steps used when this landed.
- Should carapace's blanket `compdef` list ever grow expensive to snapshot/restore against
  (large `_comps` in an unusual setup), the fallback layer is the one part of this design
  that's separable — dropping `zzz_carapace.zsh` costs only long-tail coverage, not the
  apply-time generation this ADR is actually about.
