# Command history (XDG state location; falls back if XDG vars unset)
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=50000
SAVEHIST=50000

setopt hist_ignore_all_dups   # drop older duplicate of a command
setopt hist_ignore_space      # don't record commands prefixed with a space
setopt hist_reduce_blanks     # collapse superfluous whitespace
setopt hist_verify            # expand history into the line buffer before running
setopt extended_history       # record timestamp + duration per entry
setopt inc_append_history     # write each command as it's entered, not on exit
