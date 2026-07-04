# Terminfo-based navigation keys + terminal application mode. Queued into
# zsh-vi-mode's post-init hook (see keybindings.zsh) so the plugin doesn't wipe them.
# NOTE: Ctrl-R is intentionally NOT bound here — atuin owns it (keybindings.zsh).

typeset -ga zvm_after_init_commands

_user_terminfo_keybindings() {
  typeset -A key
  key[Home]=${terminfo[khome]}
  key[End]=${terminfo[kend]}
  key[Insert]=${terminfo[kich1]}
  key[Delete]=${terminfo[kdch1]}
  key[Up]=${terminfo[kcuu1]}
  key[Down]=${terminfo[kcud1]}
  key[Left]=${terminfo[kcub1]}
  key[Right]=${terminfo[kcuf1]}
  key[PageUp]=${terminfo[kpp]}
  key[PageDown]=${terminfo[knp]}

  [[ -n "${key[Home]}"     ]] && bindkey "${key[Home]}"     beginning-of-line
  [[ -n "${key[End]}"      ]] && bindkey "${key[End]}"      end-of-line
  [[ -n "${key[Insert]}"   ]] && bindkey "${key[Insert]}"   overwrite-mode
  [[ -n "${key[Delete]}"   ]] && bindkey "${key[Delete]}"   delete-char
  [[ -n "${key[Up]}"       ]] && bindkey "${key[Up]}"       up-line-or-history
  [[ -n "${key[Down]}"     ]] && bindkey "${key[Down]}"     down-line-or-history
  [[ -n "${key[Left]}"     ]] && bindkey "${key[Left]}"     backward-char
  [[ -n "${key[Right]}"    ]] && bindkey "${key[Right]}"    forward-char
  [[ -n "${key[PageUp]}"   ]] && bindkey "${key[PageUp]}"   history-beginning-search-backward
  [[ -n "${key[PageDown]}" ]] && bindkey "${key[PageDown]}" history-beginning-search-forward

  # Fixed sequences some terminals send for these keys.
  bindkey "^[[5~" history-beginning-search-backward
  bindkey "^[[6~" history-beginning-search-forward
  bindkey "^[[1~" beginning-of-line
  bindkey "^[[4~" end-of-line
  bindkey "^[[H"  beginning-of-line
  bindkey "^[[F"  end-of-line

  # Option+Left/Right word navigation (xterm-style modifier sequences)
  bindkey "^[[1;3D" backward-word
  bindkey "^[[1;3C" forward-word

  # Word boundaries stop at symbols (bash-style), so word-nav/kill feel familiar
  autoload -U select-word-style
  select-word-style bash
}
zvm_after_init_commands+=('_user_terminfo_keybindings')

# Put the terminal in application mode while ZLE is active so the $terminfo key
# sequences above are valid. add-zle-hook-widget *stacks* with zsh-vi-mode's own
# line-init/finish (cursor shaping) rather than clobbering it.
autoload -Uz add-zle-hook-widget
_user_zle_appmode_init()   { echoti smkx 2>/dev/null }
_user_zle_appmode_finish() { echoti rmkx 2>/dev/null }
add-zle-hook-widget line-init   _user_zle_appmode_init
add-zle-hook-widget line-finish _user_zle_appmode_finish
