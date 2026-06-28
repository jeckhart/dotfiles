# Keybindings layered on top of zsh-vi-mode (sheldon plugin). zsh-vi-mode resets
# keymaps during its own init, so anything touching bindkey / Ctrl-R must run
# *after* that init — we queue it into zvm_after_init_commands, which the plugin
# runs once initialized. Queue order matters:
#   1) fzf   — binds Ctrl-T (files) + Alt-C (cd)      [also grabs Ctrl-R]
#   2) atuin — rebinds Ctrl-R to its history search   [queued after fzf, so it wins]
#   3) emacs-style insert-mode overlays               [do not touch Ctrl-R]
# Terminfo nav keys + terminal application mode live in zz_keybindings.local.zsh.

# Disable terminal flow control so Ctrl-Q / Ctrl-S are usable.
stty -ixon 2>/dev/null

typeset -ga zvm_after_init_commands

# fzf native integration: Ctrl-T (files), Alt-C (cd). (fzf >= 0.48 for `fzf --zsh`.)
command -v fzf >/dev/null && zvm_after_init_commands+=('source <(fzf --zsh)')

# atuin owns Ctrl-R (queued after fzf so it wins). Up-arrow stays native (--disable-up-arrow).
command -v atuin >/dev/null && zvm_after_init_commands+=('eval "$(atuin init zsh --disable-up-arrow)"')

# emacs-style bindings on top of vi insert mode.
_user_emacs_keybindings() {
  bindkey "^A" beginning-of-line
  bindkey "^E" end-of-line
  bindkey "^K" kill-line
  bindkey "^P" history-search-backward
  bindkey "^Y" accept-and-hold
  bindkey "^N" insert-last-word
  bindkey "^Q" push-line-or-edit
  bindkey "^[b" backward-word
  bindkey "^[f" forward-word
}
zvm_after_init_commands+=('_user_emacs_keybindings')
