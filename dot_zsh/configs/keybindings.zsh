# vi mode itself is provided by the oh-my-zsh vi-mode bundle (see ~/.antigenrc).
# This file only layers handy emacs-style bindings on top of vi insert mode.

# give us access to ^Q (disable terminal flow control)
stty -ixon

# handy keybindings
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^K" kill-line
bindkey "^R" history-incremental-search-backward
bindkey "^P" history-search-backward
bindkey "^Y" accept-and-hold
bindkey "^N" insert-last-word
bindkey "^Q" push-line-or-edit
