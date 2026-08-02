#!/usr/bin/env bash
# script/lint/hook-wiring.sh — mise run doctor's hk/beads collision guard. This repo
# deliberately keeps .beads/hooks/* inert and hk as the SOLE owner of .git/hooks: wiring
# both risks hk's `exec`-based shim making anything appended after it unreachable, or
# `bd hooks install` silently clobbering hk's shim (see hk.pkl's header comment).
# Read-only — reports drift, never repairs it.

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

fail=0

hooks_path=$(git config --get core.hooksPath || true)
if [ -n "$hooks_path" ]; then
	echo "hook-wiring: core.hooksPath is set to '$hooks_path' — expected unset (hk installs directly into .git/hooks)" >&2
	fail=1
fi

pre_commit=".git/hooks/pre-commit"
if [ ! -f "$pre_commit" ]; then
	echo "hook-wiring: $pre_commit is missing — run 'mise run setup' (hk install --mise)" >&2
	fail=1
elif ! grep -q 'hk run pre-commit' "$pre_commit"; then
	echo "hook-wiring: $pre_commit exists but doesn't invoke hk — it may have been overwritten by another tool (e.g. 'bd hooks install')" >&2
	fail=1
fi

exit $fail
