# Colorized man pages via bat (replaces the oh-my-zsh colored-man-pages plugin).
# bat's theme is pinned in ~/.config/bat/config (Catppuccin Macchiato).
if command -v bat >/dev/null; then
  export MANPAGER="bat -l man -p"
  export MANROFFOPT="-c"   # fixes formatting of some man pages under a pager
fi
