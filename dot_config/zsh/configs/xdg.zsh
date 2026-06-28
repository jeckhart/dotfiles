# Redirect tool history/state into XDG dirs (parent dirs created by
# run_once_create-xdg-state-dirs.sh). Only redirects that need no data move —
# these just relocate where *new* history is written. Tools whose state must be
# migrated to take effect (aws config, cargo/rustup homes) are intentionally left
# at their defaults and handled elsewhere (rust.zsh) or not at all.
: "${XDG_STATE_HOME:=$HOME/.local/state}"

export LESSHISTFILE="$XDG_STATE_HOME/less/history"
export PYTHON_HISTORY="$XDG_STATE_HOME/python/history"
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"
