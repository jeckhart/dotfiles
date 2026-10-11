# ADR 0007: `machine-identifiers` — what a public dotfiles repo can leak, and what it can't catch

Status: Accepted

## Context

This repo is public, and it isn't just shell config: `.beads/` syncs an issue-tracking
Dolt database to `refs/dolt/data` on the same public GitHub remote (see
`docs/beads-dolt-server.md`). Both the tracked working tree and that synced ref are
readable by anyone. Beads' own notes/descriptions/comments are free text a human or
agent writes in the moment, not reviewed line-by-line the way a code diff is — the
mechanically-detectable subset of "identifying information" needs a gate that fires on
every commit, not a habit of remembering to grep before pushing.

What actually counts as identifying, for this repo specifically:

- **Radicle DIDs/RIDs** — a full `did:key:z6M…` or `rad:z…` string identifies a specific
  node or repo on the private radicle mesh (`docs/radicle.md`). The mesh is deliberately
  private (`seedingPolicy: block`, no public seeds) — leaking one of these gives an
  outsider a concrete target to probe.
- **Tailscale CGNAT addresses / MagicDNS hostnames** (the shared-address-space range
  Tailscale assigns from, and `*.ts.net` hostnames) — identify a specific machine's
  reachable address on the private tailnet the radicle mesh rides on.
- **Email addresses** — mostly this identity's own (already public via commit
  authorship — see the allowlist below) or, more sensitively, a work identity's.
- **RFC1918 private IPs** (`10/8`, `172.16/12`, `192.168/16`) — internal network
  topology, occasionally informative even without a hostname attached.
- **Arbitrary machine hostnames** — genuinely out of scope. No fixed pattern
  distinguishes "gerald" the hostname from any other word in a commit message; this
  class relies on review and `bd memories`, not mechanization. Documented as a known
  limit, not silently dropped.

Building a gate for exactly the *mechanically-detectable* subset, then explicitly naming
what's left to human judgment, was the only version of this that doesn't overpromise.

## Decision

`hk.pkl`'s `machine-identifiers` step scans every tracked file (`glob = "**/*"`) against
one regex covering all five detectable classes, on every commit and every CI run — not
opt-in, not sampled.

**Three allowlisted strings**, hardcoded because they're already-public identity, not
leaks:

- `rad:z4L8L9ctRYn2bcPuUT4GRz7sggG1v` — `docs/radicle.md`'s own worked example RID.
- `jeckhart@hey.com` — this identity's personal email, visible on every commit's
  authorship metadata regardless (allowlisting it here doesn't expose anything a `git
  log` doesn't already).
- `z6MkrLMMsiPWUcNPHcRajuMi9mDfYckSoJyPwwnknocNYPm7@seed.radicle.garden` —
  `rad-clone-public.tmpl`'s default *public* seed address (radicle.garden's own seed
  service, incidentally shaped like an email address to this regex).

**Two structural exclusions**, not allowlist entries, because the content they exclude
would otherwise flag against the gate's own fixtures: `hk.pkl` itself (its `tests {}`
blocks necessarily embed fake-but-pattern-matching DIDs/emails/IPs to exercise the
pass/fail cases) and `script/lint/mock-bin/**` (its canned 1Password test doubles use
radicle-nid-shaped fake data on purpose).

**Work/client identity is a roster, not a hardcoded includeIf list.** The one place this
repo used to name real employer/client directories in a tracked file
(`dot_config/git/config.local.tmpl`'s `includeIf` blocks) now ranges over a `roster`
field on a `git-work-dirs` 1Password item instead (`onepasswordRead`). Git history was
**not** rewritten to scrub the old hardcoded list — 223 commits, invalidating 84 already-
signed commits for marginal benefit against history that (a) is already public and (b)
Renovate/GitHub don't retroactively re-scan anyway.

**The beads Dolt DB itself is not scanned by this gate.** `machine-identifiers` covers
the tracked working tree; `.beads/issues.jsonl` (the passive export) is included in
that tree and so gets swept, but the live Dolt DB that syncs to `refs/dolt/data` is a
separate sync path this gate never touches. An `hk` pre-push step was the original plan;
verified it structurally can't work — `bd dolt push` never invokes `.git/hooks/pre-push`
(Dolt's push protocol doesn't shell out to `git push`; confirmed by watching hk's own log
file across a real `bd dolt push` — it never updated). Shipping that step anyway would
have been a gate that looks like protection but never actually fires. Deferred as a
research bead (`dotfiles-4ab.11`) around a Dolt-native `CREATE TRIGGER` or a reactive
CI-side scan, instead of shipping something structurally inert.

## Consequences

**What this makes easy:** the mechanically-detectable classes (DIDs, RIDs, Tailscale
addresses, emails, private IPs) cannot land in a tracked file without a human explicitly
overriding the check — there's no "forgot to grep before committing" failure mode for
this subset.

**What this makes harder, on purpose:** hostnames, and anything else with no fixed
syntactic shape, still depend on review discipline (`bd memories`, reading a diff before
push) rather than a gate. Adding heuristics here (a hostname allowlist, an NLP pass) was
considered and rejected — the false-positive rate on ordinary English words would make
the gate noisy enough to train people to ignore its output, which is worse than the gap
it would half-close.

**Known, accepted gap:** the beads Dolt DB's live sync path is unscanned until
`dotfiles-4ab.11` lands. Anything written into a beads issue/comment/note between now and
then reaches the public remote the same way any other git content does — via `bd dolt
push` — with no automated check standing between a careless write and that push.
