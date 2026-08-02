#!/usr/bin/env bash
# script/lint/chezmoi-templates.sh — hk's chezmoi-templates step (hk.pkl). Renders every
# passed *.tmpl file under each fixture in script/lint/profiles/*.toml and shellchecks
# any render whose output is a shell script. Two failure classes:
#   - a Go-template render error (bad syntax, unknown field)  -> hard fail
#   - a shellcheck finding in the rendered output              -> hard fail
# An empty render is a legitimate skip (a platform branch that yields nothing on this
# profile), not a failure.
#
# .chezmoi.toml.tmpl is skipped outright: it's chezmoi's own init-time config template
# (uses `promptString`, only defined under `chezmoi init`/`execute-template --init`),
# not deployed content, so this gate never renders it at all.
#
# Templates calling `onepasswordRead`/`onepassword`, or shelling out to the `op`/
# `op.exe` CLI directly (the radicle templates' enrollment probe), go through
# mock-bin/{op,op.exe} instead of a live 1Password session — deterministic, offline,
# and identical locally and in CI (which has no real `op` binary at all). See
# mock-bin/op's header for the exact argv shapes it answers to. The stderr-pattern
# check below is now a defensive fallback only: it should never fire in normal
# operation, since the mock always succeeds — if it does fire, that's a signal the
# mock needs extending for some new 1Password code path, not an accepted steady state.
#
# Known limit: .chezmoi.os/.chezmoi.arch come from the real runtime, not the [data]
# fixtures below — this script only ever exercises the OS-gated branches for the OS
# it's running on. The CI workflow's ubuntu-latest + macos-latest matrix covers both.

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$repo_root"

# Deterministic 1Password stand-in — see mock-bin/op's header. Prepended, not appended,
# so it wins over any real `op`/`op.exe` already on PATH.
export PATH="$repo_root/script/lint/mock-bin:$PATH"

profiles_dir="script/lint/profiles"
shopt -s nullglob
profiles=("$profiles_dir"/*.toml)
shopt -u nullglob
if [ "${#profiles[@]}" -eq 0 ]; then
	echo "chezmoi-templates: no profiles found in $profiles_dir" >&2
	exit 1
fi

skip_structural=".chezmoi.toml.tmpl"

tmp_render=$(mktemp)
tmp_err=$(mktemp)
trap 'rm -f "$tmp_render" "$tmp_err"' EXIT

fail=0

is_shell_render() {
	# $1: first line of the render. Deliberately narrow (sh/bash only, optionally via
	# /usr/bin/env) — a false negative here just skips shellcheck coverage on a render
	# that happens to be some other language, not a false pass on shell.
	case "$1" in
	'#!/bin/sh' | '#!/bin/bash' | '#!/usr/bin/env sh' | '#!/usr/bin/env bash') return 0 ;;
	*) return 1 ;;
	esac
}

for f in "$@"; do
	[ "$f" = "$skip_structural" ] && continue
	[ -f "$f" ] || continue # deleted/renamed file in this changeset

	for profile in "${profiles[@]}"; do
		if ! chezmoi execute-template --config "$profile" --file "$f" >"$tmp_render" 2>"$tmp_err"; then
			if grep -qE 'onepasswordRead|op\.exe|op (read|item)|not found on PATH|1Password is locked' "$tmp_err"; then
				echo "chezmoi-templates: SKIP $f ($profile): hit a 1Password code path mock-bin/op doesn't cover — extend the mock, this shouldn't happen" >&2
				continue
			fi
			echo "chezmoi-templates: FAIL $f ($profile): template render error" >&2
			sed 's/^/  /' "$tmp_err" >&2
			fail=1
			continue
		fi

		[ -s "$tmp_render" ] || continue # empty render: legitimate platform-branch skip

		first_line=$(head -n1 "$tmp_render")
		# -e SC1091: several of these scripts source "$HOME/.config/..." paths that are
		# only known at chezmoi-apply time, not statically — shellcheck can never follow
		# them, and that's expected/unfixable here, not a real bug. Excluding this one code
		# (not raising the whole severity floor) matters: SC2086 — the classic unquoted-
		# variable finding — is ALSO info-severity, so a floor of "warning" would silently
		# swallow it too (confirmed: `shellcheck -S warning` passes `rm -rf $X` clean).
		if is_shell_render "$first_line" && ! shellcheck -e SC1091 "$tmp_render" >"$tmp_err" 2>&1; then
			echo "chezmoi-templates: FAIL $f ($profile): shellcheck findings in rendered output" >&2
			sed -e "s|$tmp_render|$f (rendered)|" -e 's/^/  /' "$tmp_err" >&2
			fail=1
		fi
	done
done

exit $fail
