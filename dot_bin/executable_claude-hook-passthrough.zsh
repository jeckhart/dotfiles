#!/usr/bin/env zsh
# claude-hook-passthrough — run a PreToolUse command-rewrite hook, except for a git
# command, which it lets through unrewritten. See docs/adr/0008.
#
# Claude Code's own worktree-isolation guard refuses to run a git invocation it finds
# wrapped as an operand of a launcher it doesn't recognize — it cannot verify the wrap
# stays inside the isolated worktree. `rtk hook claude` rewrites `git status` to
# `rtk git status`; `caveman shrink-hook` rewrites it to `caveman shrink -- git status`.
# Either rewrite alone makes every git command in a worktree-isolated session unrunnable,
# with no override — this is the harness's own guard, not this repo's agent-git-guard.
#
# Usage: claude-hook-passthrough.zsh [--worktree-only] -- <real-hook-command...>
#   (no flag)         skip the rewrite for every git command, everywhere
#   --worktree-only   skip the rewrite for a git command only when `cwd` is a
#                     `.claude/worktrees/` isolation root; rewrite normally elsewhere
#
# Reads the same PreToolUse JSON the real hook would get, on stdin. When skipping,
# exits 0 with no stdout — "no rewrite, run the command exactly as written", which the
# isolation guard can then read and verify. Otherwise re-emits the payload, unread, to
# the real hook command given after `--`.
emulate -L zsh
set -eu

worktree_only=0
[[ ${1-} == --worktree-only ]] && { worktree_only=1; shift }
[[ ${1-} == -- ]] && shift
(( $# > 0 )) || { print -u2 -- "claude-hook-passthrough: missing real hook command after --"; exit 1 }

payload=$(cat)

# Can't tell whether this is a git command without jq — run the real hook rather than
# silently drop the rewrite for everything (fail toward the pre-existing behavior).
if ! command -v jq >/dev/null 2>&1; then
	print -rn -- "$payload" | "$@"
	exit
fi

cmd=$(print -rn -- "$payload" | jq -r '.tool_input.command // ""' 2>/dev/null) || cmd=""
cwd=$(print -rn -- "$payload" | jq -r '.cwd // ""' 2>/dev/null) || cwd=""

# Whole-word "git" anywhere in the command — matches the guard's own trigger surface
# (it flags git named as an operand at any depth, not just argv[0]). Over-matching just
# means one fewer rewrite for a command that happens to mention "git" without running
# it; under-matching would let a real block back in.
is_git_command=0
[[ $cmd =~ '(^|[^[:alnum:]_.-])git([^[:alnum:]_.-]|$)' ]] && is_git_command=1

in_worktree=0
[[ $cwd == */.claude/worktrees/* ]] && in_worktree=1

if (( is_git_command )) && { (( ! worktree_only )) || (( in_worktree )) }; then
	exit 0
fi

print -rn -- "$payload" | "$@"
