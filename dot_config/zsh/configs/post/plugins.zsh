# Source sheldon's compiled plugin script. POST phase, so it runs AFTER
# completion.zsh has run compinit — required because fzf-tab must initialize
# after the completion system exists.
#
# Plugin order (vi-mode → fzf-tab → autosuggestions → syntax-highlighting-last)
# is defined in ~/.config/sheldon/plugins.toml. Keybindings that must survive
# zsh-vi-mode's init (fzf Ctrl-T/Alt-C, atuin Ctrl-R, the emacs/terminfo binds)
# are queued into zvm_after_init_commands by earlier configs and fire from here.
#
# Tradeoff: we use the dynamic `eval "$(sheldon source)"` — fast (Rust), simple.
# To shave the subprocess, cache it instead:
#   sheldon source > "${XDG_DATA_HOME:-$HOME/.local/share}/sheldon/source.zsh"
# and source that file, regenerating via a chezmoi run_onchange_ keyed on
# plugins.toml's hash.
command -v sheldon >/dev/null && eval "$(sheldon source)"
