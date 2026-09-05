#!/usr/bin/env bash
# script/lint/modify-scripts-test.sh — hk's modify-scripts step (hk.pkl). Fixture suite
# for this repo's `modify_` chezmoi targets (ADR-0003): each one is a jq pipeline whose
# job is to edit a *live*, runtime-written file in place — Claude Code's own
# ~/.claude/settings.json, Docker's own ~/.config/docker/config.json — enforcing only a
# few owned keys and passing everything else through untouched.
#
# The regression class this guards against is specific: a `modify_` script that renders
# cleanly and passes its own shellcheck pass (chezmoi-templates.sh covers that) while
# still corrupting live state — reordering keys so `chezmoi status` never goes clean,
# or discarding a runtime key nobody told it to own. Both bugs shipped and went
# unnoticed for a while, because neither shows up as a template render error, and a
# plain idempotence check (rendered output fed through itself) does NOT catch
# key-reordering either — the reordered output is already a fixed point against
# itself, it just disagrees with what came before it. So these fixtures feed a
# synthetic *live* file — deliberately in non-canonical key order, with an unknown key
# no template author would think to seed — through the real rendered script, and
# assert the property that matters: live content survives, unknown keys pass through,
# and (where the script claims to) key order is preserved exactly.
#
# Isolated: renders happen in a scratch dir (mktemp -d, cleaned up on exit); no chezmoi
# apply, no real ~/.claude or ~/.config/docker touched. mock-bin/op is unnecessary here
# (neither script calls onepasswordRead) but harmless to include for parity with the
# other lint scripts' PATH setup.

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$repo_root"
export PATH="$repo_root/script/lint/mock-bin:$PATH"

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

fail=0

render() {
	# $1: template path, $2: output path
	chezmoi execute-template --source "$repo_root" \
		--config script/lint/profiles/darwin.toml --file "$1" >"$2"
	chmod +x "$2"
}

echo "--- dot_claude/modify_settings.json.tmpl ---" >&2
render dot_claude/modify_settings.json.tmpl "$scratch/modify_settings"

# Non-canonical key order (desired's own order is tui/theme/model/statusLine — this
# input deliberately doesn't match), an unknown runtime key Claude Code might write
# (advisorModel), and a deliberately stale statusLine value the owned-key enforcement
# must still overwrite.
live_settings='{"attribution":{"commit":""},"model":"opusplan","advisorModel":"x","tui":"fullscreen","theme":"auto","statusLine":{"type":"command","command":"stale"}}'
out=$("$scratch/modify_settings" <<<"$live_settings")

# `hooks` is a legitimate addition (the agent-git-guard reconciliation adds it when
# absent, per ADR-0005) — exclude it before comparing order of the keys that were
# actually in the live input.
got_keys=$(jq -c '[keys_unsorted[] | select(. != "hooks")]' <<<"$out")
want_keys=$(jq -c 'keys_unsorted' <<<"$live_settings")
if [ "$got_keys" != "$want_keys" ]; then
	echo "modify-scripts: FAIL settings.json key order not preserved: got $got_keys, want $want_keys" >&2
	fail=1
fi
if [ "$(jq -r '.advisorModel' <<<"$out")" != "x" ]; then
	echo "modify-scripts: FAIL settings.json dropped an unknown live key (advisorModel)" >&2
	fail=1
fi
if [ "$(jq -r '.statusLine.command' <<<"$out")" = "stale" ]; then
	echo "modify-scripts: FAIL settings.json did not enforce the owned statusLine key" >&2
	fail=1
fi

echo "--- dot_config/docker/modify_config.json.tmpl ---" >&2
render dot_config/docker/modify_config.json.tmpl "$scratch/modify_docker"

# currentContext + a second auths entry: exactly the runtime state the plain-template
# predecessor of this script used to silently discard on every apply.
live_docker='{"auths":{"a":{}, "b":{}},"credsStore":"stale","currentContext":"colima","features":{"buildkit":"false"}}'
out=$("$scratch/modify_docker" <<<"$live_docker")

if [ "$(jq -r '.currentContext' <<<"$out")" != "colima" ]; then
	echo "modify-scripts: FAIL docker config.json dropped currentContext" >&2
	fail=1
fi
if [ "$(jq -c '.auths' <<<"$out")" != "$(jq -c '.auths' <<<"$live_docker")" ]; then
	echo "modify-scripts: FAIL docker config.json dropped or altered .auths" >&2
	fail=1
fi
if [ "$(jq -r '.credsStore' <<<"$out")" = "stale" ]; then
	echo "modify-scripts: FAIL docker config.json did not enforce the owned credsStore key" >&2
	fail=1
fi

if [ "$fail" -eq 0 ]; then
	echo "modify-scripts-test: all fixtures passed" >&2
fi
exit $fail
