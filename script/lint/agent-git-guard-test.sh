#!/usr/bin/env bash
# script/lint/agent-git-guard-test.sh — hk's agent-git-guard step (hk.pkl). Table-driven
# fixture suite for dot_bin/executable_agent-git-guard.zsh: every row of its rule table
# (docs/adr/0005-agent-git-guardrails.md), plus the shell-tokenization edge cases a
# substring-grep guard gets wrong (env/global-opt prefixes, nested `bash -c`, a `-a` or
# `#` that's really just text inside a quoted commit message) and the override-marker
# edge cases (valid/short/empty reason, and the absolute stage-all tier refusing it).
#
# Isolated from the real world: XDG_STATE_HOME points at a scratch dir so this never
# touches ~/.local/state/agent-git-guard/log.jsonl, and every fixture goes through the
# guard's own `check` subcommand (exit code only — no JSON/hook payload involved).
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
guard="$repo_root/dot_bin/executable_agent-git-guard.zsh"

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export XDG_STATE_HOME="$scratch/state"

fail=0

# expect: "block" (exit 2) or "allow" (exit 0). Command is always $2 verbatim — no
# further quoting/escaping happens here, so table entries read exactly as a human would
# type them.
check() {
	local expect="$1" cmd="$2"
	local rc=0
	"$guard" check "$cmd" >/dev/null 2>/tmp/agent-git-guard-test.err || rc=$?
	local want=2
	[[ $expect == allow ]] && want=0
	if [[ $rc != "$want" ]]; then
		printf 'FAIL (got exit %s, want %s): %s\n' "$rc" "$want" "$cmd" >&2
		cat /tmp/agent-git-guard-test.err >&2
		fail=1
	fi
}

# ---- stage-all (absolute — no override, not even with a marker) -------------------
check block 'git add -A'
check block 'git add --all'
check block 'git add .'
check block 'git add ./'
check block 'git add :/'
check block 'git add "*"'
check block 'git add -u'
check block 'git commit -a -m wip'
check block 'git commit -am wip'
check block 'git commit --all -m wip'
check block 'git aa' # alias: add --all
check allow 'git add path/to/a path/to/b'
check allow 'git add -u src/'
check allow 'git add -A src/'
check allow 'git add -p'
check block 'git add -A # guard-ok: user said so' # marker ignored on this tier
check block 'git add -A # guard-ok: user explicitly authorized this exact command'

# ---- worktree (override-able) ------------------------------------------------------
check block 'git reset --hard'
check block 'git clean -fd'
check block 'git clean -f'
check block 'git checkout -- .'
check block 'git checkout .'
check block 'git restore .'
check block 'git restore --staged .'
check allow 'git reset'
check allow 'git reset HEAD~1'
check allow 'git reset -- src/foo.rs'
check allow 'git restore src/foo.rs'
check allow 'git checkout -b feat/x'
check allow 'git checkout main'
check allow 'git clean -n'

# ---- rewrite (override-able) -------------------------------------------------------
check block 'git push --force'
check block 'git push -f'
check block 'git push --force-with-lease'
check block 'git pf' # alias: push --force-with-lease
check block 'git commit --amend'
check block 'git filter-branch --tree-filter true'
check block 'git reflog expire --expire=now --all'
check block 'git update-ref -d refs/heads/x'
check block 'git gc --prune=now'
check block 'git branch -D feat/x'
check block 'git bdf feat/x' # alias: branch -D
check allow 'git push'
check allow 'git push -u origin feat/x'
check allow 'git rebase origin/main'
check allow 'git commit --fixup=HEAD~1'
check allow 'git branch -d feat/x'
check allow 'git bd feat/x' # alias: branch -d

# ---- bypass (override-able) --------------------------------------------------------
check block 'git commit --no-verify'
check block 'git commit -n -m wip'
check block 'git push --no-verify'
check block 'git merge --no-verify main'
check block 'git rebase --no-verify main'

# ---- sweep (override-able) ----------------------------------------------------------
check block 'git stash'
check block 'git stash push'
check block 'git stash push -m wip'
check block 'git stash drop'
check block 'git stash clear'
check block 'git config --global core.editor vim'
check block 'git config --system core.editor vim'
check allow 'git stash push -- src/foo.rs'
check allow 'git stash list'
check allow 'git stash show'
check allow 'git stash pop'
check allow 'git config --global --get core.editor'
check allow 'git config core.editor vim' # repo-local, not --global/--system

# ---- shell-level tokenization: the cases a substring grep gets wrong ---------------
check block 'git -C /x add -A'
check block 'cd sub && git add -A'
check block 'cd sub && git commit -am wip'
check block "bash -c 'git add -A'"
check block "sh -c 'git reset --hard'"
check allow 'echo "never run git add -A"'
check allow 'git commit -m "fix -a bug"'
check allow 'git commit -m "fix # guard-ok: nope"' # no rule hit at all here — safe as-is
check allow "rg 'git add -A'"
check allow 'FOO=bar git status'

# ---- override marker: extraction, validation, and the quoting edge case -----------
check allow 'git push --force # guard-ok: user asked after the rebase'
check block 'git push --force # guard-ok:'                 # empty reason
check block 'git push --force # guard-ok: ok'              # denylisted non-reason
check block 'git push --force # guard-ok: yes'             # denylisted non-reason
check block 'git push --force'                             # no marker at all
check block 'git commit --amend -m "fix # guard-ok: nope"' # marker is inside quotes
check block 'git add -A # guard-ok: user said so'          # stage-all ignores it

if ((fail)); then
	echo "agent-git-guard-test: one or more fixtures failed (see above)" >&2
	exit 1
fi
echo "agent-git-guard-test: all fixtures passed"
