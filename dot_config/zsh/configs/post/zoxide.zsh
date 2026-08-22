# zoxide: frecency directory jumper. `z <partial>` jumps, `zi` is interactive.
# Deliberately NOT `--cmd cd`: keep literal `cd` for relative navigation (frecency
# can otherwise jump into the wrong project's subdir). Stack-based back-tracking is
# the `d` / `1`-`9` aliases (see aliases.zsh); zoxide is cross-session frecency.
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
