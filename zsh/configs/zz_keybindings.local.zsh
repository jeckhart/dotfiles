[[ "${terminfo[kpp]}" != "" ]] && bindkey "${terminfo[kpp]}" up-line-or-beginning-search   # [PageUp] - search forward
[[ "${terminfo[knp]}" != "" ]] && bindkey "${terminfo[knp]}" down-line-or-beginning-search # [PageDown] - search backward
[[ "${terminfo[khome]}" != "" ]] && bindkey "${terminfo[khome]}" beginning-of-line # [Home] - search backward
[[ "${terminfo[kend]}" != "" ]] && bindkey "${terminfo[kend]}" end-of-line       # [End] - search backward
bindkey '^[[1;6C' forward-word                                                   # [Ctrl-Shift-RightArrow] - move forward one word
bindkey '^[[1;6D' backward-word                                                  # [Ctrl-Shift-LeftArrow] - move backward one word
