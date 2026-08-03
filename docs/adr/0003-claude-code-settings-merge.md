# ADR 0003: Merge `~/.claude/settings.json` via `modify_`, never overwrite it

Status: Accepted

## Context

`~/.claude/` was entirely unmanaged. A hand-written `~/.claude/statusline-command.sh`
(Catppuccin Mocha/Latte statusline) and a `statusLine` entry in
`~/.claude/settings.json` existed only on this machine, with no path to reproduce
either on a new one.

Two constraints rule out the obvious approach of `chezmoi add`-ing `settings.json`
whole:

**The repo is public.** An audit of `~/.claude/` found exactly two files safe to
publish — `settings.json` and `statusline-command.sh`. Everything else is either live
OAuth credentials (`.credentials.json`) or identity/telemetry (`backups/*.claude.json.backup.*`
carries a work email, org name, org/account UUIDs, an owner role, machine/user IDs,
private repo paths, and spend data), plus verbatim conversation transcripts
(`projects/`, 6 MB), prompt history (`history.jsonl`), and other machine state. None of
that can enter this repo, by mistake or otherwise.

**Claude Code writes `settings.json` at runtime.** `/advisor` writes `advisorModel`,
`/effort` writes `effortLevel`, `/fast` writes `fastMode`, and the `/config` UI writes
`enableArtifact`; other in-session changes (theme, model) may land there too. There is
no `~/.claude/settings.d/` drop-in or include mechanism for user-scope settings, and no
documented dotfiles pattern for this file. A plain chezmoi-managed file would mean
`chezmoi apply` silently reverts whatever was just set interactively, and `chezmoi diff`
shows permanent, uninvestigable drift.

## Decision

Manage `~/.claude/settings.json` with a **`modify_` script**
(`dot_claude/modify_settings.json.tmpl`) rather than a plain file. A `modify_` target
receives the current file on stdin and its stdout becomes the new file — evaluated on
every `chezmoi apply`, and diffed like any other target.

The script merges three layers, last one winning:

```text
seeds (tui, theme, model) < live file < owned (statusLine)
```

- **Owned** keys (`statusLine`) are re-enforced on every apply, replacing whatever is
  live. `statusLine` is owned because it names the managed `statusline-command.sh` by
  path — the two have to move together, and a `/config` change that clears `statusLine`
  should self-heal on the next apply.
- **Seeded** keys (`tui`, `theme`, `model`) are written only when the file doesn't have
  them yet; once present, the live value always wins. These are exactly the keys a
  session can change interactively — owning them would fight the user's own `/config`
  or `/model` calls.
- Any other key Claude Code writes (`advisorModel`, `effortLevel`, `fastMode`,
  `enableArtifact`, …) passes through untouched; the script never enumerates them.

Implementation, in jq: `$d * .` (recursive merge, live file wins) then a `reduce` over
`$owned` that force-assigns each owned key from `$desired`. `$desired` is the single
literal both the merge and the no-jq fallback read, so there's one place to edit, not
two.

Rejected alternatives:

- **Plain managed file.** Clobbers every runtime write; rejected outright per the
  Context above.
- **`run_onchange_` + jq.** Keyed on the *script's own* content hash, not the target
  file's state — if `/config` clears `statusLine`, the script's text hasn't changed, so
  it never re-runs and the statusline stays broken until the next unrelated edit to the
  script. Also invisible to `chezmoi diff`, so drift can't be inspected before applying.
- **`create_` (seed-once).** The file already exists on every machine this matters for,
  so a create-only file is a permanent no-op — it can never deliver `statusLine` or any
  future change.

The no-`jq` branch is the fresh-machine happy path, not just a defensive fallback:
chezmoi applies targets in target-name order, and `.claude/settings.json` sorts before
`install-packages.sh` alphabetically, so on a first bootstrap `jq` isn't installed yet
when this script runs. Empty stdin (file doesn't exist) still emits `$desired`
verbatim; a populated file is passed through untouched with a stderr warning, never
guessed at without `jq` to parse it.

`.gitignore` gets a deny-by-default block scoped to `dot_claude/`:

```gitignore
dot_claude/*
!dot_claude/executable_statusline-command.sh
!dot_claude/modify_settings.json.tmpl
```

`gitleaks` (run by `hk` on every commit) can catch obvious credential patterns, but not
an org UUID, a work email, or a private repo path — nothing about those *looks* like a
secret. Blocking the whole directory except two explicit negations means a stray
`chezmoi add ~/.claude/<anything-else>` can't reach git even if the mistake isn't
caught by review.

## Consequences

- Steady-state `chezmoi diff` on `settings.json` is empty: the merge is idempotent, and
  jq's key ordering (`$d`'s keys first) matches the live file's, so a no-op merge is
  byte-identical.
- Interactive settings survive `chezmoi apply`: change `theme` via `/config`, apply,
  `theme` is unchanged. Delete `statusLine` by hand, apply, it's restored. Add an
  unrelated key by hand, apply, it survives.
- **To manage another key**: add it to `$desired`, and additionally to `owned` if it
  should be enforced rather than merely seeded on first run. Prefer seeding — own a key
  only when something else in the repo depends on its exact value, the way
  `statusLine` depends on the path to the managed script.
- **Never-commit inventory for `~/.claude/`**, durable record of what was excluded and
  why: `.credentials.json` (live OAuth access/refresh tokens), `backups/` (work email,
  org name, org/account UUIDs, owner role, machine/user IDs, private repo paths, spend
  telemetry), `projects/` (verbatim transcripts), `history.jsonl` (verbatim prompts),
  `sessions/`, `shell-snapshots/`, `session-env/`, `cache/`, `paste-cache/`,
  `file-history/`, `downloads/`, `remote-settings.json`, `policy-limits.json`
  (employer's Claude policy posture), `.last-cleanup`, `plugins/` (vendored code plus
  absolute and private-repo paths).
- **Ambiguous cases, excluded for now**: `plans/` (no credentials, but discloses machine
  setup and references a private repo — Claude-generated churn, not reproducible
  config); `plugins/installed_plugins.json` and `known_marketplaces.json` (the plugin
  *identities* would be useful for reproducibility, but the files as they exist bake in
  absolute and private-repo paths and Claude rewrites them, so committing them as-is
  would both leak and drift — if wanted later, express as a templated allowlist of
  plugin names, never by copying the file).
- The repo's own `.claude/settings.json` (a `bd prime` SessionStart hook, for hacking on
  this repo) is unrelated to this ADR — it's structurally undeployable (chezmoi requires
  a `dot_` prefix to represent a hidden target) and stays a plain repo file.
- **Incidental fix, found by testing this script's no-jq fallback under a stripped
  `PATH`:** `.chezmoitemplates/brew/shellenv` referenced `$HOMEBREW_PREFIX` unguarded in
  two places, which errors under `set -eu` (`nounset`) whenever Homebrew isn't already on
  `PATH` and the variable was never set — the exact fresh-bootstrap case the partial
  exists to handle. `script/setup`'s own copy of this ladder already guards the same
  reference (`"${HOMEBREW_PREFIX:-}/bin/brew"`); the shared partial now matches it. Fixes
  a latent bug in all four existing `set -eu` consumers
  (`run_onchange_install-packages.sh.tmpl`, `run_onchange_after_install-yazi-packages.sh.tmpl`,
  `run_onchange_after_install-mise-tools.sh.tmpl`, `run_onchange_after_build-bat-cache.sh.tmpl`),
  not just this one.
