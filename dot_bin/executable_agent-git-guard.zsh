#!/usr/bin/env zsh
# agent-git-guard — PreToolUse/beforeShellExecution guard against blind git staging and
# other destructive git invocations. Shared, unmodified, across Claude Code, Cursor, and
# Codex: all three treat exit 2 + a stderr message as "deny" (see docs/adr/0005).
#
# Modes:
#   (no args)     hook mode — read {"tool_input":{"command":...}} (Claude/Codex) or
#                 {"command":...} (Cursor) JSON from stdin. Exit 2 + stderr denies the
#                 tool call; exit 0 allows it. Fails OPEN on anything unexpected
#                 (malformed JSON, missing jq, an internal parse error) — a guard that
#                 wedges every Bash call is worse than one that occasionally misses.
#   check '<cmd>' evaluate a literal command string; exit code only, no JSON wrapper.
#                 Used by script/lint/agent-git-guard-test.sh.
#   log [-n N]    print the last N (default 20) audit log entries.
#   rules         print the rule/tier table.
#
# Tiers (AGENT_GIT_GUARD_TIERS=tier,tier,... overrides which are enabled; default: all):
#   stage-all  add/stage -A|--all|--no-ignore-removal|bare -u, a repo-wide add pathspec,
#              commit -a/--all (incl. -am). ABSOLUTE — see "Override" below.
#   worktree   reset --hard, clean -f, checkout/restore with a repo-wide pathspec.
#   rewrite    push --force*, commit --amend, filter-branch, reflog expire, update-ref -d,
#              gc --prune=now, branch -D.
#   bypass     commit/push/merge/rebase --no-verify (or commit -n).
#   sweep      bare stash (push), stash drop/clear, config --global/--system writes.
#
# Override: append `# guard-ok: <reason>` (>=8 chars, not a placeholder) to the command.
# Honor-system, not enforcement — it waives every override-able tier hit in that command
# and is written to the audit log alongside every block, so the log is the actual control.
# The stage-all tier ignores the marker entirely (there is always a correct alternative:
# stage by path) — a marker attempted there is itself logged as override-refused.
#
# Kill switch: AGENT_GIT_GUARD=off|0 in THIS PROCESS's own environment exits 0
# immediately. Deliberately not read from the inspected command string — that would let
# an agent grant itself the override in a child shell we never see.
#
# Parsing uses zsh's own lexer (${(z)}), not a regex/shlex approximation — see
# docs/adr/0005-agent-git-guardrails.md for why (measured: zsh forks for free here,
# python did not, and ${(z)} gets quoting right where shlex/grep don't).

emulate -L zsh
setopt extended_glob

# ---- config -----------------------------------------------------------------------

typeset -gA AGG_TIER_ENABLED
AGG_TIER_ENABLED=(stage-all 1 worktree 1 rewrite 1 bypass 1 sweep 1)
if [[ -n ${AGENT_GIT_GUARD_TIERS:-} ]]; then
	local _t
	for _t in stage-all worktree rewrite bypass sweep; do AGG_TIER_ENABLED[$_t]=0; done
	for _t in ${(s:,:)AGENT_GIT_GUARD_TIERS}; do AGG_TIER_ENABLED[$_t]=1; done
fi

# Aliases (dot_config/git/config) that expand to something a rule cares about. Aliases
# that expand to something harmless (co, st, lg, ...) are deliberately omitted — the
# git-alias-drift hk step asserts every alias expanding to a BLOCKED command is listed
# here, not that every alias is.
typeset -gA AGG_ALIAS
AGG_ALIAS=(
	aa "add --all"
	pf "push --force-with-lease"
	bdf "branch -D"
)

AGG_LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/agent-git-guard"
AGG_LOG_FILE="$AGG_LOG_DIR/log.jsonl"
AGG_LOG_MAX_BYTES=$((5 * 1024 * 1024))

typeset -ga AGG_SEP
AGG_SEP=(';' '&&' '||' '|' '&' '(' ')' '{' '}')

typeset -ga AGG_HITS AGG_FLAGS AGG_PATHS AGG_TOP_WORDS AGG_NESTED_WORDS
typeset -ga __AGG_SEG __AGG_GITARGS __AGG_SUBARGS __AGG_STASH_REST
typeset -g AGG_REASON=""

# ---- small helpers ------------------------------------------------------------------

agg_reason_valid() {
	local r="$1"
	[[ -z $r ]] && return 1
	(( ${#r} >= 8 )) || return 1
	case "${(L)r}" in
	ok | yes | sure | fine | n/a | because | "-") return 1 ;;
	esac
	return 0
}

agg_is_repo_wide_path() {
	case "$1" in
	. | ./ | :/ | :/. | "*") return 0 ;;
	*) return 1 ;;
	esac
}

agg_any_repo_wide() {
	local p
	for p in "${AGG_PATHS[@]}"; do
		agg_is_repo_wide_path "$p" && return 0
	done
	return 1
}

agg_has_flag() {
	local f pat
	for f in "${AGG_FLAGS[@]}"; do
		for pat in "$@"; do
			[[ $f == ${~pat} ]] && return 0
		done
	done
	return 1
}

agg_hit() {
	local tier="$1" rule="$2"
	[[ ${AGG_TIER_ENABLED[$tier]:-0} == 1 ]] || return 0
	AGG_HITS+=("$tier|$rule")
}

# Splits an args array (git subcommand argv, e.g. everything after `git commit`) into
# AGG_FLAGS (options, clustered short opts expanded, value-taking ones carrying
# `flag=value`) and AGG_PATHS (positional pathspec/ref args). $1 = name of the source
# array variable, $2 = space-separated list of value-taking long/short option spellings
# for THIS subcommand (e.g. "-m -F --author").
agg_split() {
	local -a args
	args=("${(@P)1}")
	local -a value_opts
	value_opts=(${=2})
	AGG_FLAGS=()
	AGG_PATHS=()
	local no_more_opts=0 i=1 a
	while (( i <= ${#args} )); do
		a="${args[i]}"
		if (( no_more_opts )); then
			AGG_PATHS+=("${(Q)a}")
			(( i++ ))
			continue
		fi
		if [[ $a == "--" ]]; then
			no_more_opts=1
			(( i++ ))
			continue
		fi
		if [[ $a == -[A-Za-z][A-Za-z]* && $a != --* ]]; then
			# Clustered short opts (-am -> -a -m). If the LAST expanded flag is a
			# value-taking option, the value is the next token, same as if it had
			# been written standalone.
			local clustered="${a#-}" lastf j
			for (( j = 1; j <= ${#clustered}; j++ )); do
				AGG_FLAGS+=("-${clustered[j]}")
			done
			lastf="-${clustered[${#clustered}]}"
			if (( ${value_opts[(Ie)$lastf]} )); then
				(( i++ ))
				(( i <= ${#args} )) && AGG_FLAGS+=("${lastf}=${(Q)args[i]}")
			fi
			(( i++ ))
			continue
		fi
		if [[ $a == -* ]]; then
			local flagname="${a%%=*}"
			AGG_FLAGS+=("$a")
			if [[ $a != *=* ]] && (( ${value_opts[(Ie)$flagname]} )); then
				(( i++ ))
				(( i <= ${#args} )) && AGG_FLAGS+=("${flagname}=${(Q)args[i]}")
			fi
			(( i++ ))
			continue
		fi
		AGG_PATHS+=("${(Q)a}")
		(( i++ ))
	done
}

# ---- git-specific parsing -------------------------------------------------------------

# $1 = name of args array (everything after `git`, i.e. global opts + subcommand + its args)
agg_check_git() {
	local -a args
	args=("${(@P)1}")
	local i=1
	while (( i <= ${#args} )); do
		case "${args[i]}" in
		-C | -c)
			(( i += 2 )) ;;
		--git-dir=* | --work-tree=* | --exec-path=*)
			(( i += 1 )) ;;
		--no-pager | --bare | --no-optional-locks | --no-replace-objects | -p | --paginate | \
			--literal-pathspecs | --no-literal-pathspecs | --no-advice)
			(( i += 1 )) ;;
		*)
			break ;;
		esac
	done
	(( i > ${#args} )) && return 0
	local -a rest
	rest=("${(@)args[i,-1]}")
	local sub="${(Q)rest[1]}"
	rest=("${(@)rest[2,-1]}")

	if [[ -n ${AGG_ALIAS[$sub]:-} ]]; then
		local -a expansion
		expansion=(${(z)AGG_ALIAS[$sub]})
		sub="${expansion[1]}"
		rest=("${(@)expansion[2,-1]}" "${(@)rest[@]}")
	fi

	__AGG_SUBARGS=("${(@)rest[@]}")
	agg_apply_rules "$sub"
}

# Reads subcommand args from the global __AGG_SUBARGS (set by agg_check_git just above).
agg_apply_rules() {
	local sub="$1"

	case "$sub" in
	add | stage)
		agg_split __AGG_SUBARGS ""
		if agg_has_flag '-A' '--all' '--no-ignore-removal'; then
			(( ${#AGG_PATHS} == 0 )) && agg_hit stage-all add-all
		fi
		if agg_has_flag '-u' '--update'; then
			(( ${#AGG_PATHS} == 0 )) && agg_hit stage-all add-update-bare
		fi
		agg_any_repo_wide && agg_hit stage-all add-dot
		;;
	commit)
		agg_split __AGG_SUBARGS "-m -F -C --author --date --fixup --squash -S --gpg-sign"
		agg_has_flag '-a' '--all' && agg_hit stage-all commit-all
		agg_has_flag '--amend' && agg_hit rewrite commit-amend
		agg_has_flag '-n' '--no-verify' && agg_hit bypass commit-no-verify
		;;
	reset)
		agg_split __AGG_SUBARGS ""
		agg_has_flag '--hard' && agg_hit worktree reset-hard
		;;
	clean)
		agg_split __AGG_SUBARGS ""
		agg_has_flag '-f*' '--force' && agg_hit worktree clean-force
		;;
	checkout)
		agg_split __AGG_SUBARGS "-b -B --orphan --conflict"
		agg_any_repo_wide && agg_hit worktree checkout-dot
		;;
	restore)
		agg_split __AGG_SUBARGS "-s --source"
		agg_any_repo_wide && agg_hit worktree restore-dot
		;;
	push)
		agg_split __AGG_SUBARGS "-o --push-option --receive-pack"
		agg_has_flag '-f' '--force' '--force-with-lease*' '--force-if-includes' &&
			agg_hit rewrite push-force
		agg_has_flag '--no-verify' && agg_hit bypass push-no-verify
		;;
	filter-branch)
		agg_hit rewrite filter-branch
		;;
	reflog)
		[[ "${__AGG_SUBARGS[1]:-}" == expire ]] && agg_hit rewrite reflog-expire
		;;
	update-ref)
		agg_split __AGG_SUBARGS ""
		agg_has_flag '-d' '--delete' && agg_hit rewrite update-ref-delete
		;;
	gc)
		agg_split __AGG_SUBARGS "--aggressive"
		agg_has_flag '--prune=now' && agg_hit rewrite gc-prune-now
		;;
	branch)
		agg_split __AGG_SUBARGS ""
		agg_has_flag '-D' && agg_hit rewrite branch-force-delete
		if agg_has_flag '-d' '--delete'; then
			agg_has_flag '-f' '--force' && agg_hit rewrite branch-force-delete
		fi
		;;
	merge | rebase)
		agg_split __AGG_SUBARGS ""
		agg_has_flag '--no-verify' && agg_hit bypass "${sub}-no-verify"
		;;
	stash)
		# `git stash` with no subcommand at all behaves exactly like `stash push`, so
		# both must land in the SAME branch below with the SAME (empty) leftover args
		# — the subcommand word itself must never reach agg_split, or "push" is
		# mistaken for a pathspec (which is the bug this comment is guarding against).
		local first
		if (( ${#__AGG_SUBARGS} == 0 )); then
			first="push"
			__AGG_STASH_REST=()
		else
			first="${__AGG_SUBARGS[1]}"
			__AGG_STASH_REST=("${(@)__AGG_SUBARGS[2,-1]}")
		fi
		case "$first" in
		drop) agg_hit sweep stash-drop ;;
		clear) agg_hit sweep stash-clear ;;
		push | save)
			agg_split __AGG_STASH_REST "-m --message"
			(( ${#AGG_PATHS} == 0 )) && agg_hit sweep stash-bare
			;;
		esac
		;;
	config)
		agg_split __AGG_SUBARGS ""
		if agg_has_flag '--global' '--system'; then
			agg_has_flag '--get' '--get-all' '--get-regexp' '--list' '-l' ||
				agg_hit sweep config-global-write
		fi
		;;
	esac
}

# ---- shell-level tokenizing/segmenting ------------------------------------------------

# $1 = name of a word-array variable, $2 = recursion depth
#
# Builds each `;`/`&&`/`|`-delimited segment into the GLOBAL __AGG_SEG (not a local
# named e.g. `seg`) before handing it to agg_scan_segment: zsh's `${(@P)name}` indirection
# resolves against whatever scope first declares that name, so a callee that happened to
# `local -a seg` of its own would shadow the caller's data and silently read empty (this
# bit once — see the always-block note above for why fail-open still caught it).
agg_scan_words() {
	local -a words
	words=("${(@P)1}")
	local depth="${2:-0}"
	(( depth > 3 )) && return 0
	__AGG_SEG=()
	local w
	for w in "${words[@]}"; do
		if (( ${AGG_SEP[(Ie)$w]} )); then
			agg_scan_segment __AGG_SEG "$depth"
			__AGG_SEG=()
		else
			__AGG_SEG+=("$w")
		fi
	done
	agg_scan_segment __AGG_SEG "$depth"
}

agg_evaluate_nested() {
	local nested="$1" depth="$2"
	AGG_NESTED_WORDS=(${(z)nested})
	agg_scan_words AGG_NESTED_WORDS "$depth"
}

# $1 = name of a word-array variable holding one `;`/`&&`/`|`-delimited segment. Its own
# local is deliberately NOT named the same as anything a caller up the stack might pass
# (see the note on agg_scan_words above).
agg_scan_segment() {
	local -a segwords
	segwords=("${(@P)1}")
	local depth="$2"
	(( ${#segwords} == 0 )) && return 0

	while (( ${#segwords} > 0 )) && [[ ${segwords[1]} == [A-Za-z_][A-Za-z0-9_]#=* ]]; do
		segwords=("${(@)segwords[2,-1]}")
	done
	(( ${#segwords} == 0 )) && return 0

	while (( ${#segwords} > 0 )); do
		case "${segwords[1]:t}" in
		env | sudo | command | nohup | time | xargs) segwords=("${(@)segwords[2,-1]}") ;;
		*) break ;;
		esac
	done
	(( ${#segwords} == 0 )) && return 0

	local prog="${(Q)${segwords[1]:t}}"

	if [[ $prog == (bash|sh|zsh) ]] && (( ${#segwords} >= 3 )) && [[ ${segwords[2]} == -c ]]; then
		agg_evaluate_nested "${(Q)segwords[3]}" $(( depth + 1 ))
		return 0
	fi
	if [[ $prog == eval ]] && (( ${#segwords} >= 2 )); then
		local -a evalrest
		evalrest=("${(@)segwords[2,-1]}")
		agg_evaluate_nested "${(j: :)${(@Q)evalrest}}" $(( depth + 1 ))
		return 0
	fi

	[[ $prog == git ]] || return 0
	__AGG_GITARGS=("${(@)segwords[2,-1]}")
	agg_check_git __AGG_GITARGS
}

# Extracts a trailing `# guard-ok: <reason>` marker (a genuine unquoted shell comment —
# ${(z)} keeps quoted text inside its word, so a `#` inside a quoted -m message never
# reaches here) and returns the comment-stripped word list in AGG_TOP_WORDS.
agg_extract_top_level() {
	local raw="$1"
	local -a words
	words=(${(z)raw})
	local i n=${#words}
	AGG_REASON=""
	for (( i = 1; i <= n; i++ )); do
		if [[ ${words[i][1]} == '#' ]]; then
			if (( i < n )) && [[ ${words[i + 1]} == "guard-ok:" ]]; then
				AGG_REASON="${(j: :)${(@Q)words[i + 2, -1]}}"
			fi
			words=("${(@)words[1, i - 1]}")
			break
		fi
	done
	AGG_TOP_WORDS=("${(@)words}")
}

# ---- logging ---------------------------------------------------------------------

agg_log() {
	local event="$1" tier="$2" rule="$3" raw="$4" cwd="$5" agent="$6" reason="$7"
	command -v jq >/dev/null 2>&1 || return 0
	[[ -d $AGG_LOG_DIR ]] || mkdir -p -m 700 -- "$AGG_LOG_DIR" 2>/dev/null || return 0
	if [[ -f $AGG_LOG_FILE ]]; then
		local size
		size=$(wc -c <"$AGG_LOG_FILE" 2>/dev/null) || size=0
		(( size > AGG_LOG_MAX_BYTES )) && mv -f -- "$AGG_LOG_FILE" "$AGG_LOG_FILE.1" 2>/dev/null
	fi
	local ts
	ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
	jq -nc \
		--arg ts "$ts" --arg event "$event" --arg tier "$tier" --arg rule "$rule" \
		--arg command "$raw" --arg cwd "$cwd" --arg agent "$agent" --arg reason "$reason" \
		'{ts: $ts, event: $event, tier: $tier, rule: $rule, command: $command, cwd: $cwd, agent: $agent, reason: $reason}' \
		>>"$AGG_LOG_FILE" 2>/dev/null
	chmod 600 -- "$AGG_LOG_FILE" 2>/dev/null
}

# ---- evaluation entry point --------------------------------------------------------

agg_print_refusal() {
	local tier="$1" rule="$2" raw="$3"
	if [[ $tier == stage-all ]]; then
		cat >&2 <<MSG
BLOCKED by agent-git-guard [$tier:$rule]: $raw

\`git add -A\` (and its cousins --all / . / :/ / bare -u, and \`commit -a\`) stage every
change in the worktree — including work from other agents, GitButler, and edits you did
not make. This rule has no override. Stage only what you changed, by path:

    git add path/to/a path/to/b

Run \`git status --porcelain\` first if you are unsure what you touched.
MSG
	else
		cat >&2 <<MSG
BLOCKED by agent-git-guard [$tier:$rule]: $raw

This is a destructive or history-rewriting git operation. If the user explicitly asked
for this, retry with an authorization marker naming who asked and why (>= 8 characters):

    $raw # guard-ok: user asked me to <the specific thing they asked for>

Markers are written to the audit log ($AGG_LOG_FILE) and reviewed later. Do not add one
on your own initiative — only when the user actually asked for this exact operation.
MSG
	fi
}

# $1=command string  $2=cwd  $3=agent label (for the audit log)
agg_evaluate_and_report() {
	local raw="$1" cwd="$2" agent="$3"

	if [[ ${AGENT_GIT_GUARD:-} == (off|0) ]]; then
		return 0
	fi

	AGG_HITS=()
	agg_extract_top_level "$raw"
	agg_scan_words AGG_TOP_WORDS 0

	(( ${#AGG_HITS} == 0 )) && return 0

	local -a blocking
	local hit tier rule
	for hit in "${AGG_HITS[@]}"; do
		tier="${hit%%|*}"
		rule="${hit#*|}"
		if [[ $tier == stage-all ]]; then
			blocking+=("$hit")
			if [[ -n $AGG_REASON ]]; then
				agg_log override-refused "$tier" "$rule" "$raw" "$cwd" "$agent" "$AGG_REASON"
			else
				agg_log blocked "$tier" "$rule" "$raw" "$cwd" "$agent" ""
			fi
		elif agg_reason_valid "$AGG_REASON"; then
			agg_log waived "$tier" "$rule" "$raw" "$cwd" "$agent" "$AGG_REASON"
		else
			blocking+=("$hit")
			agg_log blocked "$tier" "$rule" "$raw" "$cwd" "$agent" ""
		fi
	done

	(( ${#blocking} == 0 )) && return 0

	tier="${blocking[1]%%|*}"
	rule="${blocking[1]#*|}"
	agg_print_refusal "$tier" "$rule" "$raw"
	return 2
}

# ---- dispatch -----------------------------------------------------------------------

agg_detect_agent_from_payload() {
	local input="$1"
	if [[ -n ${CLAUDECODE:-} ]]; then
		print -r -- claude
		return
	fi
	if command -v jq >/dev/null 2>&1 && print -r -- "$input" | jq -e 'has("cursor_version")' >/dev/null 2>&1; then
		print -r -- cursor
		return
	fi
	if [[ -n ${CODEX_HOME:-}${CODEX_SANDBOX_NETWORK_DISABLED:-} ]]; then
		print -r -- codex
		return
	fi
	print -r -- unknown
}

agg_dispatch_hook() {
	local input
	input=$(cat)
	[[ -z $input ]] && exit 0
	[[ $input == *git* ]] || exit 0
	command -v jq >/dev/null 2>&1 || exit 0

	local cmd cwd agent
	cmd=$(print -r -- "$input" | jq -r '(.tool_input.command // .command // empty)' 2>/dev/null)
	[[ -z $cmd ]] && exit 0
	cwd=$(print -r -- "$input" | jq -r '(.cwd // empty)' 2>/dev/null)
	agent=$(agg_detect_agent_from_payload "$input")

	agg_evaluate_and_report "$cmd" "${cwd:-$PWD}" "$agent"
	exit $?
}

agg_dispatch_check() {
	agg_evaluate_and_report "${1:-}" "$PWD" manual
	exit $?
}

agg_dispatch_log() {
	local n=20
	[[ ${1:-} == -n ]] && n="${2:-20}"
	if [[ ! -f $AGG_LOG_FILE ]]; then
		print -r -- "agent-git-guard: no log yet ($AGG_LOG_FILE)"
		return 0
	fi
	command -v jq >/dev/null 2>&1 || { cat "$AGG_LOG_FILE"; return 0 }
	tail -n "$n" -- "$AGG_LOG_FILE" | jq -r '
    "\(.ts)  \(.event)  \(.tier)/\(.rule)  \(.cwd)  \(.agent)\n    \(.command)"
    + (if (.reason // "") != "" then "\n    \"\(.reason)\"" else "" end)
  '
}

agg_dispatch_rules() {
	cat <<'RULES'
tier       override  rules
stage-all  never     add -A/--all/--no-ignore-removal (bare); add w/ repo-wide pathspec;
                     add -u/--update (bare); commit -a/--all (incl. -am)
worktree   yes       reset --hard; clean -f; checkout/restore w/ repo-wide pathspec
rewrite    yes       push -f/--force/--force-with-lease; commit --amend; filter-branch;
                     reflog expire; update-ref -d; gc --prune=now; branch -D
bypass     yes       commit/push/merge/rebase --no-verify (or commit -n)
sweep      yes       bare stash (push); stash drop/clear; config --global/--system write

Override: append `# guard-ok: <reason>` (>=8 chars) to an override-able-tier command.
stage-all ignores the marker — it has no override.
RULES
}

agg_main() {
	case "${1:-}" in
	check)
		shift
		agg_dispatch_check "$@"
		;;
	log)
		shift
		agg_dispatch_log "$@"
		;;
	rules)
		agg_dispatch_rules
		;;
	"")
		agg_dispatch_hook
		;;
	*)
		print -r -- "agent-git-guard: unknown mode '$1'; failing open" >&2
		exit 0
		;;
	esac
}

# Any hard zsh runtime error (a bad substitution from an unanticipated shell shape, an
# out-of-bounds array index) unwinds to here rather than propagating a stray nonzero exit
# from something that was never meant to be a rule verdict — always fail OPEN. Confirmed
# this does not swallow a deliberate `exit 2`/`exit 0` from agg_main itself (see
# docs/adr/0005 for the verification transcript).
{
	agg_main "$@"
} always {
	if (( TRY_BLOCK_ERROR )); then
		print -r -- "agent-git-guard: internal error; failing open" >&2
		exit 0
	fi
}
