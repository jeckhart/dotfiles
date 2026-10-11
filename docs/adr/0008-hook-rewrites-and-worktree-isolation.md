# ADR 0008: A passthrough shim keeps rtk/caveman's rewrite hooks from wrapping git

Status: Accepted

## Context

A Claude Code session isolated in a worktree (`EnterWorktree`, or a subagent spawned with
`isolation: "worktree"`) could not run **any** git command — not even `git --version` —
each refused with:

> This session is isolated in the worktree …, but this command runs rtk with a git
> command among its operands: what runs it, and from which directory or root, cannot be
> read here … Refusing to run it.

This is Claude Code's own worktree-isolation guard, not this repo's
[agent-git-guard](0005-agent-git-guardrails.md) (that guard's denials carry a distinct
`PreToolUse:Bash hook error: [<path>]` label; these don't). The guard statically analyzes
a proposed command and refuses one that names `git` as an operand of a launcher it
doesn't recognize — it can't prove the wrapped invocation stays inside the isolated
worktree, so it declines rather than guess. Confirmed independently upstream:
[rtk-ai/rtk#3864](https://github.com/rtk-ai/rtk/issues/3864) (open, filed 2026-09-12,
reproduced on macOS and Windows, rtk 0.47–0.49).

`~/.claude/settings.json`'s `hooks.PreToolUse` carries two command-rewriting hooks, and
either one alone reproduces the bug:

- `rtk hook claude` rewrites `git status` → `rtk git status`.
- `caveman shrink-hook` rewrites `git status` → `caveman shrink -- git status`.

Both tools already receive `cwd` in the hook payload and ignore it — neither has a
built-in way to skip the rewrite inside a worktree.

### caveman's git rewrite has no upside to give up

Bytes of agent-visible output, this repo's main checkout, `rtk git <cmd>` vs.
`caveman shrink -- git <cmd>`:

| command | raw | rtk | caveman |
| --- | --- | --- | --- |
| `git status` | 332 | **50** | 459 |
| `git status --porcelain` | 29 | **28** | 154 |
| `git diff HEAD~3` | 638730 | **74922** | 637272 |
| `git diff HEAD~3 --stat` | 3669 | **3668** | 3798 |
| `git log --oneline -30` | 2766 | **2761** | 2895 |
| `git branch -vv` | **522** | 1014 | 651 |
| `git worktree list` | 207 | **141** | 334 |
| `git show --stat HEAD` | **5923** | 5923 | 6054 |

caveman's `shrink` is larger than the raw command on every row (a fixed banner, ~0
compression on git's own already-compact output) — and because it is registered without
a matcher and fires after rtk's hook in the same PreToolUse pass, its rewrite silently
wins and clobbers rtk's whenever a plain (non-piped/non-redirected) command reaches it.
Verified live: a plain `git status` returned caveman's uncompressed 332-byte form with
`"ratio":0` — so today caveman's git rewrite is net-negative in *every* session, worktree
or not, not only the ones that hit the isolation guard.

rtk has no stdin-filter mode for git — every subcommand runs the child itself, which is
exactly the shape the guard refuses. The one fallback that exists, piping a raw diff
through `rtk diff -`, gives up most of the savings (447 KB vs. 75 KB for the same diff)
and only covers `diff`. Inside a worktree, git runs unwrapped; caveman's separate
PostToolUse *Caveman Engine* (`caveman-proxy native-hook`, an unrelated hook that
compresses tool **output** after the fact rather than rewriting the command) still
applies, so output compression isn't lost — only the git-specific input rewrite is.

## Decision

`dot_bin/executable_claude-hook-passthrough.zsh` wraps both rewrite hooks. It reads the
same PreToolUse JSON the real hook would receive, and either re-feeds it unchanged to
the real hook or exits 0 with no stdout ("no rewrite — run the command exactly as
written", which the isolation guard can then read and verify):

- `rtk hook claude` is wrapped with `--worktree-only`: skip the rewrite only when `cwd`
  is under `.claude/worktrees/`; rewrite normally everywhere else, keeping rtk's real
  savings (above) in ordinary sessions.
- `caveman shrink-hook` is wrapped with no flag: skip the rewrite for a git command
  everywhere, given the negative-value table above. Non-git commands still route through
  unaffected.

`dot_claude/modify_settings.json.tmpl`'s existing hook reconciliation (ADR-0005) gained
a fourth managed entry (caveman's) and a second stale-detector: `caveman hooks install`
writes its raw, unwrapped `<resolved-path> shrink-hook` with no marker, and the resolved
path varies by machine (unlike rtk's PATH-relative `rtk hook claude`), so the reconciler
matches it by suffix (`endswith(" shrink-hook")`) rather than by exact string.

### Why a wrapper script, not a config knob in either tool

Neither tool currently has a cwd-aware skip:

- rtk's `[hooks] exclude_commands` (`config.toml`) matches the raw command text, not the
  resolved launcher, and is global — turning it off for `git` would give up rtk's git
  savings in every session to fix a case that only occurs inside worktrees.
- caveman's `shrinkHook()` checks `nativeProfile()`/`tool_name` only; it has no cwd
  branch at all.

A wrapper is the only lever available without patching either tool, and it's the same
shape the community landed on independently
([rtk-ai/rtk#3864](https://github.com/rtk-ai/rtk/issues/3864), comment from `awmwong`).

### Why not just stop wrapping git in rtk too

`rtk git <cmd>` measurably beats raw output on every row above except `branch -vv` and
`show --stat` — real savings this repo already relies on
(`3486d0e feat(rtk): install rtk and manage its Claude Code hook + config`). Losing that
everywhere to fix a worktree-only bug would be a strictly worse trade than skipping it
only where it actually breaks.

## Consequences

- git works in a worktree-isolated session again, unrewritten — no rtk/caveman
  compression there, but the isolation guard was the one actually blocking it, and
  neither tool has a safe cwd-aware alternative to offer instead.
- Ordinary (non-worktree) sessions keep rtk's git savings and stop losing them to
  caveman's shrink-hook clobbering the rewrite after the fact.
- **Known hazard, called out at the point of failure:** `rtk gain` detects its own hook
  by string-matching `settings.json` for the literal `rtk hook claude`; wrapped, it no
  longer finds itself and prints `[warn] No hook installed — run 'rtk init -g'` (stderr
  only, harmless by itself). Acting on that advice re-writes the raw form and
  reintroduces this bug until the next `chezmoi apply` reconciles it away — the same trap
  applies to `caveman hooks install`. Neither tool's own advice can be trusted here;
  `chezmoi apply` is the recovery path, not either CLI's self-repair.
- Upstream still owns the actual fix (a cwd-aware skip inside `rtk hook claude` and
  `caveman shrink-hook` themselves): [rtk-ai/rtk#3864](https://github.com/rtk-ai/rtk/issues/3864)
  is open; nothing is filed against caveman yet.
