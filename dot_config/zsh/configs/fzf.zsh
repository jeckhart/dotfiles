# fzf environment (the native keybinding integration `source <(fzf --zsh)` is
# registered in keybindings.zsh via zvm_after_init_commands so zsh-vi-mode can't
# clobber Ctrl-T/Alt-C). fzf >= 0.48 required for `fzf --zsh`.

# Use fd for traversal: respects .gitignore, includes hidden, skips .git.
if command -v fd >/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# Previews: bat for files, eza --tree for directories.
_fzf_preview='if [ -d {} ]; then eza --tree --color=always --level=2 {} | head -200; else bat -n --color=always --line-range :500 {}; fi'
export FZF_CTRL_T_OPTS="--preview '$_fzf_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --level=2 {} | head -200'"
unset _fzf_preview

# Catppuccin Macchiato palette — APPEND so we don't clobber the layout/preview opts above.
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
  --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 \
  --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
  --color=marker:#b7bdf8,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796 \
  --color=selected-bg:#494d64 \
  --color=border:#6e738d,label:#cad3f5"
