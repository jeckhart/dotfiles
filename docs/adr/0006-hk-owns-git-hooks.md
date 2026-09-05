# ADR 0006: hk is the sole owner of `.git/hooks`; `.beads/hooks/*` stays inert

Status: Accepted

## Context

Two tools in this repo are each capable of installing git hooks: `hk` (this repo's
quality-gate runner, `hk.pkl`) and `bd` (beads, the issue tracker, via `bd hooks
install`). Both want the same four or five hook slots — at minimum `pre-commit` and
`pre-push`.

`hk install --mise` writes a one-line shim into e.g. `.git/hooks/pre-commit`:

```sh
#!/bin/sh
test "${HK:-1}" = "0" || exec mise x -- hk run pre-commit --from-hook "$@"
```

That `exec` replaces the shell process outright — it never returns, so nothing appended
after it in the same file would ever run. `bd hooks install` writes its own
`.git/hooks/pre-commit` for the same slot, independently, with no awareness of hk's.
Whichever tool installs second wins the file; there is no cooperative append protocol
between them. Two failure modes follow directly:

- If `bd hooks install` runs after `hk install`, it silently overwrites hk's shim —
  every quality gate in `hk.pkl` (shellcheck, shfmt, gitleaks, `chezmoiignore-drift`,
  `agent-git-guard`, …) stops running on commit, with no error, just quietly gone.
- If `hk install` runs after `bd hooks install`, the reverse happens to beads' hook
  behavior, and — because of the `exec` — there was never a way to make hk's shim
  gracefully chain into whatever beads' hook did, even if both existed.

`.beads/hooks/` (`pre-commit`, `pre-push`, `post-checkout`, `post-merge`,
`prepare-commit-msg`) already exists as tracked, vendored content — beads' own scaffold,
generated when the beads workspace was set up. It looks installable. It has never
actually been installed here.

## Decision

**hk is the sole owner of `.git/hooks`.** `.beads/hooks/*` stays exactly as beads
generated it — present in the repo, tracked, but never copied or symlinked into
`.git/hooks/`. Nobody runs `bd hooks install` in this repo, ever.

The only installation path is `mise run setup` (`mise.toml`'s `[tasks.setup]`, `run = "hk
install --mise"`), and it's a no-op to run twice: `hk install` doesn't care that beads
never touched `.git/hooks/`, it just writes its own shims. `mise.toml` also sets
`postinstall = "hk install --mise"`, so a fresh `mise install` (which `script/setup` and
any contributor's first `mise` invocation trigger) re-wires the hooks automatically —
nobody has to remember `mise run setup` by name.

`script/lint/hook-wiring.sh` (wired into `mise run doctor`, not into `hk check` itself —
it inspects `.git/hooks/`, which a sandboxed `hk` check step can't assume exists or is
writable) is the read-only trip-wire: it checks `core.hooksPath` is unset (hk installs
directly into `.git/hooks/`, not a redirected path) and that `.git/hooks/pre-commit`
exists and actually invokes `hk run pre-commit`. It reports drift, it doesn't repair it —
by the time it can detect a clobbered hook, the fix is a human decision (which tool
should own it here?), not a mechanical one.

## Consequences

**What this makes easy:** one predictable place to look when "my commit didn't get
linted" — check `.git/hooks/pre-commit`'s content, not two tools' installation order.
Every quality gate this repo enforces (`hk.pkl`, ~30 steps) is guaranteed to actually run
on every commit, not silently skipped by an overwrite nobody noticed.

**What this makes harder:** if this repo ever wants beads' own git hooks (its
`post-checkout`/`post-merge` sync behavior, say), the two tools would need an actual
chaining mechanism — hk's shim would have to stop `exec`ing and instead run beads' hook
as a subprocess after its own checks pass, or vice versa. Nothing here builds toward
that; it's a real design problem, deferred rather than half-solved.

**Exception already in the codebase:** `.beads/hooks/*` is tracked but permanently
inert — a future beads upgrade could regenerate it differently, and that's fine, since
this repo never reads it. If beads' own git-hook story changes enough that installing
some of it becomes worth the interop work, that's a new ADR, not an edit to this one.
