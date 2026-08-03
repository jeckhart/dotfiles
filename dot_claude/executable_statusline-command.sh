#!/bin/bash
# Claude Code statusline.
#
# Segments (in order): cwd basename | git branch+dirty | git ahead/behind |
# model display name | context window used% | rate-limit used% (5h/7d) |
# worktree name (only inside a --worktree session) | open PR + review state.
#
# Colors: Catppuccin Mocha (dark, default) / Latte (light). Toggle with
#   CLAUDE_STATUSLINE_THEME=light   (any other value, or unset, stays Mocha)
#
# All git invocations use --no-optional-locks so the statusline never blocks
# on or contends with another git process.
#
# set -u only, deliberately no -e: several segments use `[ cond ] && action` as a bare
# statement, which errexit would treat as a failing command and abort mid-render.
set -u

input=$(cat)

jget() { printf '%s' "$input" | jq -r "$1"; }

# ---- palette -------------------------------------------------------------
if [ "${CLAUDE_STATUSLINE_THEME:-dark}" = "light" ]; then
	# Catppuccin Latte
	C_RED="#d20f39"
	C_MAROON="#e64553"
	C_PEACH="#fe640b"
	C_YELLOW="#df8e1d"
	C_GREEN="#40a02b"
	C_TEAL="#179299"
	C_SKY="#04a5e5"
	C_MAUVE="#8839ef"
	C_LAVENDER="#7287fd"
	C_OVERLAY="#9ca0b0"
else
	# Catppuccin Mocha
	C_RED="#f38ba8"
	C_MAROON="#eba0ac"
	C_PEACH="#fab387"
	C_YELLOW="#f9e2af"
	C_GREEN="#a6e3a1"
	C_TEAL="#94e2d5"
	C_SKY="#89dceb"
	C_MAUVE="#cba6f7"
	C_LAVENDER="#b4befe"
	C_OVERLAY="#6c7086"
fi

fg() {
	local hex="$1"
	printf '\033[38;2;%d;%d;%dm' \
		"$((16#${hex:1:2}))" "$((16#${hex:3:2}))" "$((16#${hex:5:2}))"
}

RESET=$(printf '\033[0m')
SEP=" $(fg "$C_OVERLAY")\xe2\x94\x82$RESET "

cwd=$(jget '.workspace.current_dir // .cwd')
model_name=$(jget '.model.display_name')
used_pct=$(jget '.context_window.used_percentage // empty')
five_pct=$(jget '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(jget '.rate_limits.seven_day.used_percentage // empty')
worktree_name=$(jget '.worktree.name // empty')
pr_number=$(jget '.pr.number // empty')
pr_state=$(jget '.pr.review_state // empty')

parts=()

# 1. Directory (basename only)
dir_base=$(basename "$cwd")
parts+=("$(fg "$C_LAVENDER")${dir_base}${RESET}")

# 2 & 3. Git branch/dirty + ahead/behind
if [ -n "$cwd" ] && git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
	[ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)

	if [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
		branch_color="$C_YELLOW"
		dirty_marker="*"
	else
		branch_color="$C_GREEN"
		dirty_marker=""
	fi

	if [ -n "$branch" ]; then
		parts+=("$(fg "$branch_color")${branch}${dirty_marker}${RESET}")
	fi

	ab=$(git -C "$cwd" --no-optional-locks rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)
	if [ -n "$ab" ]; then
		behind=$(printf '%s' "$ab" | awk '{print $1}')
		ahead=$(printf '%s' "$ab" | awk '{print $2}')
		ab_str=""
		[ "$ahead" != "0" ] && ab_str="↑${ahead}"
		[ "$behind" != "0" ] && ab_str="${ab_str}${ab_str:+ }↓${behind}"
		[ -n "$ab_str" ] && parts+=("$(fg "$C_TEAL")${ab_str}${RESET}")
	fi
fi

# 4. Model display name
[ -n "$model_name" ] && [ "$model_name" != "null" ] &&
	parts+=("$(fg "$C_MAUVE")${model_name}${RESET}")

# 5. Context window used%
if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
	used_int=$(printf '%.0f' "$used_pct")
	if [ "$used_int" -ge 90 ]; then
		ctx_color="$C_RED"
	elif [ "$used_int" -ge 70 ]; then
		ctx_color="$C_PEACH"
	else
		ctx_color="$C_GREEN"
	fi
	parts+=("$(fg "$ctx_color")ctx ${used_int}%${RESET}")
fi

# 6. Rate limits (5h / 7d)
rl_str=""
if [ -n "$five_pct" ] && [ "$five_pct" != "null" ]; then
	rl_str="5h:$(printf '%.0f' "$five_pct")%"
fi
if [ -n "$week_pct" ] && [ "$week_pct" != "null" ]; then
	[ -n "$rl_str" ] && rl_str="$rl_str "
	rl_str="${rl_str}7d:$(printf '%.0f' "$week_pct")%"
fi
[ -n "$rl_str" ] && parts+=("$(fg "$C_MAROON")${rl_str}${RESET}")

# 7. Worktree name (only present in a --worktree session)
if [ -n "$worktree_name" ] && [ "$worktree_name" != "null" ]; then
	parts+=("$(fg "$C_SKY")wt:${worktree_name}${RESET}")
fi

# 8. Open PR for current branch + review state
if [ -n "$pr_number" ] && [ "$pr_number" != "null" ]; then
	case "$pr_state" in
	approved) pr_color="$C_GREEN" ;;
	changes_requested) pr_color="$C_RED" ;;
	draft) pr_color="$C_OVERLAY" ;;
	*) pr_color="$C_YELLOW" ;;
	esac
	pr_str="PR #${pr_number}"
	[ -n "$pr_state" ] && [ "$pr_state" != "null" ] && pr_str="${pr_str} (${pr_state})"
	parts+=("$(fg "$pr_color")${pr_str}${RESET}")
fi

# ---- join & print ---------------------------------------------------------
output=""
for p in "${parts[@]}"; do
	if [ -z "$output" ]; then
		output="$p"
	else
		output="${output}${SEP}${p}"
	fi
done

printf '%b' "$output"
