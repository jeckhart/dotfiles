# ADR 0005: Block blind git staging via agent hooks, not a git hook

Status: Accepted

## Context

Coding agents (Claude Code, Cursor, Codex) routinely reach for `git add -A` /
`git commit -am` instead of staging the files they actually touched. In a worktree shared
with another agent, GitButler, or an in-flight edit of the user's own, that sweeps
unrelated changes into a commit. The same carelessness shows up as `git reset --hard`,
`git clean -fd`, `git push --force`, and `git commit --no-verify` (which walks straight
past this repo's hk gates).

**Git itself cannot enforce this.** There is no hook for `git add` at all, and
`git commit -a` stages its files *before* `pre-commit` runs, with nothing in the hook
environment revealing that `-a` was used. Aliasing `git` only covers interactive shells and
is trivially bypassed by an absolute path or a different alias. The only layer that sees the
actual command before it runs is each agent's own hook system.

All three agents converge on one contract: a `PreToolUse` (Claude Code, Codex) or
`beforeShellExecution` (Cursor) hook that receives the command and can deny it —
**exit code 2 with the reason on stderr** — before it executes
([Claude Code](https://code.claude.com/docs/en/hooks.md),
[Codex](https://learn.chatgpt.com/docs/hooks),
[Cursor](https://cursor.com/docs/hooks)). One script, shared unmodified across all three.

## Decision

`dot_bin/executable_agent-git-guard.zsh` parses the proposed command and denies it (exit 2)
when it matches one of five rule tiers; wiring in `~/.claude/settings.json`,
`~/.cursor/hooks.json`, and `~/.codex/hooks.json` (+ `~/.codex/config.toml`'s
`[features] hooks = true`) all point at the same script.

### Why zsh, not Python or a compiled binary

The hook fires on **every** Bash-shaped tool call, so both startup cost and shell-quoting
correctness are load-bearing, not incidental. Measured on the primary dev machine,
100 iterations each:

| Runtime | Per invocation |
| --- | --- |
| `zsh -f` | 4.9 ms |
| `/bin/sh -c true` (fork floor) | 5.0 ms |
| `python3` + `import json,shlex,re` | 37.2 ms |
| a compiled Rust/Go binary (estimated) | 1–2 ms |

zsh is free — the same cost as forking a shell at all — while Python is 7.5× the floor for
a strictly worse tokenizer: `shlex` only *approximates* POSIX shell quoting, where zsh's
`${(z)str}` is the shell's own lexer. Verified against exactly the cases a substring-grep
guard (the pre-existing `git-guardrails-claude-code` skill's approach) gets wrong:

```text
a&&b                          -> [a] [&&] [b]
echo "never git add -A"       -> [echo] [never git add -A]          # argv[0] != git
bash -c "git add -A"          -> [bash] [-c] [git add -A]           # recurse into arg
git commit -m "fix -a bug"    -> [git] [commit] [-m] [fix -a bug]   # no false -a
git commit -m "fix # nope"    -> [git] [commit] [-m] [fix # nope]   # quoted # not a comment
git add -A # guard-ok: reason -> [git] [add] [-A] [#] [guard-ok:] [reason]
```

The last two lines matter beyond correctness: the lexer distinguishes a real trailing
comment from a `#` inside a quoted `-m` message *for free*, which is exactly the
self-authorization hole the override marker (below) has to close — no regex or re-parse
needed.

Rejected:

- **Python.** Slower with a worse tokenizer (above), and it would drag `ruff`, a
  `mise.toml` entry, and two `hk.pkl` steps into a repo that otherwise has zero Python.
- **POSIX sh.** Hand-rolling a quote-aware state machine is the one thing shell is worst
  at, and POSIX sh has no arrays to hold a token list.
- **Rust/Go.** Fastest, but a public repo can't carry `darwin/arm64` + `linux/amd64`
  binaries, and building at apply time needs a toolchain present on a fresh machine.
  `hk.pkl` already relies on "no compiled code lives in this repo" to justify having no
  build step.

Two consequences, both already precedented elsewhere in this repo:

- **jq for the JSON hook payload.** Already a Brewfile dependency;
  `dot_claude/executable_statusline-command.sh` already parses hook JSON the same way. The
  guard fails open if jq is missing, same as the statusline script does.
- **No shellcheck.** `shfmt` already excludes `**/*.zsh`, and the existing `zsh-syntax` hk
  step (`zsh -n`, syntax only) already globs it — naming the file `.zsh` gets that for
  free, no `hk.pkl` change needed for it. `script/lint/agent-git-guard-test.sh` (a
  table-driven fixture suite run through the guard's own `check` subcommand) is the real
  regression net for the logic shellcheck would otherwise have covered.

### Rule tiers

| Tier | Override? | Blocked | Allowed |
| --- | --- | --- | --- |
| `stage-all` | **never** | `add`/`stage -A/--all/--no-ignore-removal`, a repo-wide `add` pathspec (`.`, `./`, `:/`, `:/.`, `*`), bare `-u`/`--update`, `commit -a/--all` (incl. `-am`) | `add <path>`, `add -u <path>`, `add -A <path>`, `add -p` |
| `worktree` | yes | `reset --hard`, `clean -f`, `checkout`/`restore` with a repo-wide pathspec | `reset`, `reset -- <file>`, `restore <file>`, `checkout -b`, `clean -n` |
| `rewrite` | yes | `push -f/--force/--force-with-lease`, `commit --amend`, `filter-branch`, `reflog expire`, `update-ref -d`, `gc --prune=now`, `branch -D` | `push`, `push -u`, `rebase`, `commit --fixup`, `branch -d` |
| `bypass` | yes | `-n`/`--no-verify` on `commit`/`push`/`merge`/`rebase` | — |
| `sweep` | yes | bare `stash`/`stash push` (no pathspec), `stash drop`/`clear`, `config --global/--system` writes | `stash push -- <file>`, `stash list/show/pop`, `config --global --get` |

`git reset` (soft/mixed) and `git restore <file>` stay allowed — only `--hard` and
repo-wide pathspecs are refused. `stage-all` is absolute because it always has a correct
alternative (stage by path); every other tier is a legitimate thing a user might actually
ask for ("rebase onto main", "force-push after that rebase", "clean up this branch's
history"), so it needs a path through — see below.

Aliases (`dot_config/git/config`'s `pf`, `bdf`, `aa`) are expanded before rule matching via
a small hardcoded map (`AGG_ALIAS` in the script); `hk.pkl`'s `git-alias-drift` step asserts
every alias that expands to a blocked command stays listed there.

### Override: `# guard-ok: <reason>`, honor-system, on the record

An override-able-tier command passes when it carries a trailing marker naming who
authorized it and why:

```bash
git push --force-with-lease # guard-ok: user asked me to force-push after the rebase
```

- Extraction falls out of the lexer for free: a bare `#` *word* starts a real shell
  comment; a `#` inside a quoted string stays part of that word. `git commit -m "fix #
  guard-ok: x"` cannot self-authorize by construction, no re-parse needed.
- The reason must be non-empty, ≥ 8 characters, and not a placeholder (`ok`, `yes`, `n/a`,
  …). A bare `# guard-ok:` is still blocked.
- `stage-all` ignores the marker entirely — attempting one there is itself logged as
  `override-refused`, the highest-signal line in the audit log.

**This is deterrence and an audit trail, not enforcement.** An agent that wants through
gets through by writing a reason; nothing here verifies the user actually said it. What it
buys: a deliberate second step, a norm of a truthful reason, and every attempt — granted or
refused — written to `${XDG_STATE_HOME:-~/.local/state}/agent-git-guard/log.jsonl`
(`agent-git-guard.zsh log` renders it). If that log ever shows an agent self-authorizing
unasked, the fix is to promote that rule to absolute or move to an out-of-band grant — not
to trust the marker more.

Considered and rejected: a `permissionDecision: "ask"` verdict that hands the decision to
the agent's own approval prompt. Simpler in principle, but it forks the implementation
three ways (Claude/Codex's JSON schema, Cursor's `permission: "ask"` schema) for a benefit
— a native UI prompt — that headless/background agent runs can't act on anyway; the
honor-system marker degrades to the same behavior (deny, log, retry) in every mode.
A per-command approval affordance can be layered on top later without changing the rule
engine.

### Failure mode: fail open

Any unexpected error — malformed hook JSON, missing jq, a hard zsh runtime error the
parsing logic didn't anticipate — exits 0 (allow) rather than blocking every subsequent
Bash call. The script's top-level dispatch runs inside a zsh `{ } always { }` block
specifically to catch the second case (verified: a deliberately triggered "bad
substitution" is caught and exits 0; a genuine `exit 2` from a real rule match passes
through the `always` block untouched). A guard that occasionally misses a real violation is
recoverable; one that wedges every Bash call in every session is not.

### Reconciling into `~/.claude/settings.json`'s `hooks.PreToolUse`

Per ADR-0003, that file merges three layers (seed < live < owned), and Claude Code's own
Supacode integration and `bd prime` already populate `hooks.PreToolUse` at runtime. Neither
existing mechanism fits a fourth entry: seeding is dead on arrival (the key already exists
live, so `$d * .` never applies it), and owning would delete the other two hooks outright.
`dot_claude/modify_settings.json.tmpl` gains a third, narrower reconciliation instead:
drop any prior `PreToolUse` entry whose command ends in a marker
(`" # chezmoi-managed-hook"`), then append the current one. Idempotent, survives Claude
Code rewriting the file at runtime, survives the guard script's path changing, and never
touches the Supacode/`bd prime` entries. `~/.cursor/hooks.json` and `~/.codex/hooks.json`
have no such competing runtime writer, so both are plain chezmoi-owned templates.

The same reconciliation now manages two more `PreToolUse` entries — rtk's and caveman's
command-rewrite hooks, each wrapped in a passthrough shim so their rewrite can't wrap a
git invocation the worktree-isolation guard would then refuse. See
[ADR-0008](0008-hook-rewrites-and-worktree-isolation.md).

## Consequences

- An agent using any of the three wired agents gets a refusal (not a silent failure) that
  names the tier/rule and either prescribes staging by path (`stage-all`) or explains the
  marker (every other tier).
- The user is unaffected: the kill switch (`AGENT_GIT_GUARD=off` in the guard's own
  environment — never read from the inspected command, so an agent can't grant itself the
  override in a child shell) plus the simple fact that these hooks only fire inside each
  agent's own tool-call path, never in an interactive terminal.
- **Known gaps, accepted for now:**
  - An absolute path to the repo root isn't recognized as a repo-wide pathspec (would need
    a `git rev-parse --show-toplevel` fork on every git-shaped command).
  - An agent can still write a file and execute it, or reach for a tool with no hook. This
    raises the cost of carelessness; it is not a sandbox.
  - Zed, opencode, and Amp publish no pre-command hook mechanism as of this writing —
    nothing to wire there.
  - `~/.cursor/` and `~/.codex/` don't yet have the same deny-by-default `.gitignore`
    allowlist `dot_claude/` has (ADR-0003) protecting against an accidental
    `chezmoi add ~/.cursor/<something-sensitive>` landing in this public repo. Not a
    problem introduced by this change (only one file is added under each), but worth the
    same treatment if either directory grows further chezmoi-managed content.
