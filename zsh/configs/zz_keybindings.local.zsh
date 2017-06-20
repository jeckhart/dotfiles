[[ "${terminfo[kpp]}" != "" ]] && bindkey "${terminfo[kpp]}" up-line-or-search   # [PageUp] - search forward
[[ "${terminfo[knp]}" != "" ]] && bindkey "${terminfo[knp]}" down-line-or-search # [PageDown] - search backward
bindkey '^[[1;6C' forward-word                                                   # [Ctrl-Shift-RightArrow] - move forward one word
bindkey '^[[1;6D' backward-word                                                  # [Ctrl-Shift-LeftArrow] - move backward one word