# [[ "${terminfo[kpp]}" != "" ]] && bindkey "${terminfo[kpp]}" up-line-or-beginning-search   # [PageUp] - search forward
# [[ "${terminfo[knp]}" != "" ]] && bindkey "${terminfo[knp]}" down-line-or-beginning-search # [PageDown] - search backward
# [[ "${terminfo[khome]}" != "" ]] && bindkey "${terminfo[khome]}" beginning-of-line # [Home] - search backward
# [[ "${terminfo[kend]}" != "" ]] && bindkey "${terminfo[kend]}" end-of-line       # [End] - search backward
# bindkey '^[[1;6C' forward-word                                                   # [Ctrl-Shift-RightArrow] - move forward one word
# bindkey '^[[1;6D' backward-word                                                  # [Ctrl-Shift-LeftArrow] - move backward one word

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

[[ -n "${key[Home]}"     ]]  && bindkey  "${key[Home]}"     beginning-of-line
[[ -n "${key[End]}"      ]]  && bindkey  "${key[End]}"      end-of-line
[[ -n "${key[Insert]}"   ]]  && bindkey  "${key[Insert]}"   overwrite-mode
[[ -n "${key[Delete]}"   ]]  && bindkey  "${key[Delete]}"   delete-char
[[ -n "${key[Up]}"       ]]  && bindkey  "${key[Up]}"       up-line-or-history
[[ -n "${key[Down]}"     ]]  && bindkey  "${key[Down]}"     down-line-or-history
[[ -n "${key[Left]}"     ]]  && bindkey  "${key[Left]}"     backward-char
[[ -n "${key[Right]}"    ]]  && bindkey  "${key[Right]}"    forward-char
[[ -n "${key[PageUp]}"   ]]  && bindkey  "${key[PageUp]}"   history-beginning-search-backward
[[ -n "${key[PageDown]}" ]]  && bindkey  "${key[PageDown]}" history-beginning-search-forward

bindkey "^[b" backward-word
bindkey "^[f" forward-word
bindkey '^R' fzf-history-widget
bindkey "^R" fzf-history-widget

bindkey "^[[5~" history-beginning-search-backward
bindkey "^[[6~" history-beginning-search-forward
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line


# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
function zle-line-init () {
    echoti smkx
}
function zle-line-finish () {
    echoti rmkx
}
zle -N zle-line-init
zle -N zle-line-finish

