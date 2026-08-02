# ADR 0002: CI enforcement + GitHub-side hardening for a public dotfiles repo

Status: Accepted

## Context

`414d982` (2026-08-02) rebuilt this repo's local enforcement from an 8-step dprint config
into the ~30-step `hk.pkl` it is today — genuinely strong local gates. But two things sat
unfinished behind it: CI had **never once passed** on either matrix leg since the workflow
was introduced, and the GitHub side of a 13-year-old public repo was essentially
unconfigured — no branch protection, no secret scanning, `GITHUB_TOKEN` defaulting to
write, Actions runnable from anywhere, no LICENSE. Meanwhile several pieces of code that
run before any of `hk.pkl`'s gates can help — `script/setup`'s Homebrew installer fetch,
sheldon's zsh plugins, TPM's tmux plugins — floated at HEAD.

This ADR records the decisions that aren't obvious from the diffs alone, several of which
reversed or narrowed what was originally planned once verified against how the actual
tools behave.

## Decision

### CI was never actually validating

`script/lint/chezmoi-templates.sh` called `chezmoi execute-template` without
`--source "$repo_root"`. Without it, chezmoi resolves `includeTemplate`/`include` against
its *default* source dir (`~/.local/share/chezmoi`) — which happens to **be** this repo on
a real dev machine, so the bug was invisible locally and only ever surfaced on a CI
runner, where every template with an `include` failed. Reproduced by isolating
`HOME`/`XDG_*` env vars locally before believing the fix (`aa5dbf5`).

A second, independent bug then surfaced once that one was fixed: `zsh` isn't preinstalled
on GitHub's `ubuntu-24.04` runner (macOS runners ship it), and it's not a mise-managed
tool — but `hk.pkl`'s `zsh-syntax` step shells out to `zsh -n` directly. Installed via
`apt-get` on the Linux leg only (`fc268ea`).

A third: `pinact`'s SHA-verification step calls the GitHub API unauthenticated by default
(60 req/hr, shared across whatever IP the runner or a local machine happens to have) and
hit that limit on both a CI run and, independently, a local run minutes apart. Fixed by
passing the job's own `GITHUB_TOKEN` as an env var, which pinact reads natively —
5000 req/hr, and grants nothing beyond a higher rate limit given the workflow's own
`permissions: contents: read` (`fbfa184`).

### GitHub ruleset: PR gate with admin self-bypass, scoped to the default branch only

`main` now requires signed commits, blocks force-push/deletion/history-rewrite, requires
linear history, and requires a PR + both CI status checks — **except** for the repo admin
role, which bypasses always. Considered and rejected: pure guardrails with no PR
requirement (weaker), and a full PR gate with no bypass (would have blocked the existing
GitButler direct-push workflow entirely). GitHub logs every bypassed rule explicitly on
each push, so the exception is visible, not silent.

**Critically scoped to `~DEFAULT_BRANCH`, never `~ALL`.** Beads syncs `refs/dolt/data` and
`refs/heads/__dolt_remote_info__` to this same GitHub remote (`.beads/config.yaml`); an
all-branches ruleset requiring signatures would have broken `bd dolt push`. Verified live
after the ruleset landed.

A parallel tag ruleset (`deletion` + `non_fast_forward`, all tags) exists for the same
reason branch protection does — nothing had protected tags either.

### Two secret-scanning sub-features are unavailable, not misconfigured

`secret_scanning` and `secret_scanning_push_protection` enabled cleanly — both free on any
public repo. `secret_scanning_non_provider_patterns` and `secret_scanning_validity_checks`
silently revert to `disabled` on every API attempt, no error returned. Confirmed via
GitHub's own docs/changelog: these are GHAS-partner features gated to org/Enterprise
licensing, not available to personal-account repos regardless of visibility. Nothing to
fix here short of moving the repo under an org with GHAS.

### Actions locked down; token permissions dropped to read by default

`allowed_actions: selected` (GitHub-owned actions + an explicit `jdx/mise-action@*`
pattern — the only two actions actually used), `sha_pinning_required: true`,
`default_workflow_permissions: read`, Actions can no longer approve PRs. The one workflow
already declared `contents: read` at job level, so this closes the hole for any *future*
workflow that forgets to.

### Renovate over Dependabot

Renovate is the only option that covers all of GitHub Actions SHAs, `mise.lock`, and (via
two custom regex managers) the sheldon/tmux plugin revs in one config
(`renovate.json`). Its first real PR (a `mise`-managed Python bump) failed CI on an
unrelated, pre-existing issue — `taplo`'s alignment check tripped on Renovate's inline
string replacement shifting a comment column by one character. Cosmetic, not a config
bug; noted as a standing minor friction for future Renovate PRs touching aligned-comment
TOML rather than something worth engineering around.

Renovate PRs are unsigned/bot-authored; with `required_signatures` in effect they need a
signed web-UI merge (GitHub signs those) rather than a green auto-merge.

### Tag-pinning stops at the bootstrap *script fetch* — not the dotfiles clone itself

README's `curl | bash` line now fetches `script/setup` from the `v1.0.0` tag rather than
`main`. `chezmoi init --apply jeckhart/dotfiles` inside that script **deliberately still
tracks `main`, unpinned**. Reproduced directly: checking out a tag leaves git in a
detached HEAD, and `git pull` hard-fails there (`You are not currently on a branch`) —
pinning that line would have silently broken `chezmoi update`/`git pull`, this repo's
entire multi-machine sync model, on every future bootstrap. Main's own ruleset (signed
commits, no force-push, admin-only bypass) already covers most of the original
unpinned-`main` threat model for a solo-maintained repo, so the marginal gain from also
pinning the clone wasn't worth that regression. (Also: pushing the annotated `v1.0.0` tag
hit a real bug in `hk` 1.54.0 — its pre-push hook fails to peel a tag object to its target
commit before computing merge-base, so it can't diff *any* annotated tag push. Worked
around with `--no-verify` for that one push only: the tag introduces no new file content,
and GitHub's tag-protection ruleset — not the local hook — is the actual boundary for
tags.)

### Plugin pinning stopped where the tooling itself can't support it

All 7 sheldon zsh plugins pin `rev = "<sha>"`, verified with an isolated `sheldon lock` +
`sheldon source` run (all 7 clone at the pinned commit; the generated source script
matches the documented load order). 5 of 6 tmux/TPM plugins pin to a tag. **`tmux-cpu`
stays unpinned** — TPM's `install_plugins.sh` only ever runs
`git clone -b "$branch" --single-branch`, with no fallback to checkout an arbitrary
commit (confirmed by reading its source and reproducing the exact failure a bare SHA
produces: `fatal: Remote branch <sha> not found in upstream origin`).
`tmux-plugins/tmux-cpu` has never tagged a release, so there is no ref TPM can use.

`script/setup`'s Homebrew installer fetch is now pinned to a commit SHA with a sha256
checksum verified before execution. `sudo -v` deliberately **stays before** the install,
not moved after it as first considered: `NONINTERACTIVE=1` needs the credential already
warmed when it runs, so reordering would break the installer on any machine without one
already cached. The checksum verification — not the ordering — is what closes the
unverified-code-with-warm-sudo gap.

### Beads Dolt DB leak-scanning: deferred, not half-built

The original plan called for an `hk` pre-push step exporting and scanning the beads Dolt
DB before it reaches the public remote (`refs/dolt/data`). Verified this doesn't work:
`bd dolt push` never invokes `.git/hooks/pre-push` at all (hk's own log file didn't
update across a real `bd dolt push` run — Dolt's push protocol doesn't shell out to
`git push`), and `bd` has no pre-push or write-time content-validation hook of its own.
Building the originally-planned step would have been security theater — a gate that
looks like protection but structurally never fires for the operation it's meant to guard.
Deferred as a research bead (`dotfiles-4ab.11`) around Dolt's native `CREATE TRIGGER`
support instead of shipping something that doesn't work.

### `machine-identifiers` extended; the employer roster moved, not deleted

The hk gate now also catches email addresses and RFC1918 private IPs (previously only
DIDs/RIDs/Tailscale addresses), with three allowlisted strings for this identity's own
already-public info (personal email, a public Radicle seed address). Swept the whole
tracked tree before landing to confirm zero false positives against existing content.

Separately, `dot_config/git/config.local.tmpl` hardcoded 5 identifying employer/client
`includeIf` blocks — now a "roster" field on a `git-work-dirs` 1Password item, ranged over
via `onepasswordRead`. Git history was **not** rewritten (223 commits, would invalidate 84
existing signed commits for marginal benefit against history that's already public).

### Shell hardening stopped short of two files, deliberately

Swept every script still missing `set -eu`/`set -euo pipefail`, checking each for real
unset-variable risk first — two scripts had a variable that's legitimately unset in a
normal code path (`SSH_AUTH_SOCK`/`DISPLAY` in `dot_ssh/rc`; `HOMEBREW_PREFIX` in
`script/setup`), fixed to `${VAR:-}` before adding `-u`, verified functionally by running
each with the variable actually unset. Two files got no `-e` at all:
`dot_bin/executable_monitor-serial.sh` (its whole job is an infinite retry loop around a
command expected to fail) and `run_before_wsl2-systemd-preflight.sh.tmpl` (its own header
comment states a "never block" charter; two of its diagnostic reads aren't guarded
against a nonzero exit).

## Consequences

- CI is green on both `ubuntu-24.04` and `macos-15` for the first time since the workflow
  existed.
- `main` cannot be force-pushed, deleted, or rewritten by anyone without the admin
  bypass, which GitHub logs explicitly every time it's used.
- `secret_scanning_non_provider_patterns` / `secret_scanning_validity_checks` stay
  disabled — not actionable on a personal-account repo; revisit only if this repo ever
  moves under an org with a GHAS license.
- The beads Dolt DB remains genuinely unscanned until `dotfiles-4ab.11`'s research lands
  on either a Dolt-native trigger or a reactive CI-side scan.
- `tmux-plugins/tmux-cpu` stays unpinned — accepted, not fixable without switching tmux
  plugin managers or forking the plugin to add a tag.
- Renovate PRs need a manual signed merge, not a green auto-merge, given
  `required_signatures`.
- Two backlog items stay explicitly out of scope, filed as `dotfiles-4ab.7`: an
  integrity digest on `hk.pkl`'s Pkl `amends` URL, and revisiting the unconditional
  `brew trust --formula can1357/tap/omp` in `run_onchange_install-packages.sh.tmpl`.
