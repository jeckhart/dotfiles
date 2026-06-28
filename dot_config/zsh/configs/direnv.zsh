# direnv: per-directory environment loading (replaces the oh-my-zsh direnv plugin).
# Hooks chpwd/precmd; no keybindings, so a plain eval here is fine.
command -v direnv >/dev/null && eval "$(direnv hook zsh)"
