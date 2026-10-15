#!/usr/bin/env zsh
# claude-hook-timer — run a Claude Code hook command and append one line per run to
# ${XDG_STATE_HOME:-~/.local/state}/claude-hooks/timing.log:
#
#   <start ISO-8601 local> <label> <duration ms> exit=<status> load=<1m 5m 15m>
#
# stdin, stdout, stderr, and the exit status pass through unchanged, so exit 2 (deny)
# still reaches Claude Code. With no command it only logs: compare a sentinel's start
# time with the prompt timestamp in the session transcript to measure spawn latency.
#
# Usage: claude-hook-timer.zsh <label> [-- <hook-command...>]
emulate -L zsh
zmodload zsh/datetime

label=${1:-unlabeled}
(( $# )) && shift
[[ ${1-} == -- ]] && shift

start=$EPOCHREALTIME
rc=0
(( $# )) && { "$@" || rc=$? }
elapsed_ms=$(( (EPOCHREALTIME - start) * 1000 ))

if [[ -r /proc/loadavg ]]; then
	load=${(j: :)${(z)"$(</proc/loadavg)"}[1,3]}
else
	load=${(j: :)${(z)"$(sysctl -n vm.loadavg 2>/dev/null)"}[2,4]}
fi

log_dir=${XDG_STATE_HOME:-$HOME/.local/state}/claude-hooks
[[ -d $log_dir ]] || mkdir -p -- $log_dir
{
	print -r -- "$(strftime '%Y-%m-%dT%H:%M:%S' ${start%.*}).${${start#*.}[1,3]} $label $(printf '%.0f' $elapsed_ms)ms exit=$rc load=$load" >>$log_dir/timing.log
} 2>/dev/null

exit $rc
