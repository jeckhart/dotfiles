# makes color constants available
autoload -U colors
colors

# enable colored output from BSD ls, etc.
export CLICOLOR=1

# LS_COLORS — Catppuccin Macchiato via vivid (cached; regenerated only when the
# vivid binary changes). Themes GNU ls, zsh completion menus, fzf-tab, AND eza's
# filekind colors consistently — and overrides any LS_COLORS inherited from the
# environment. `di` is overridden to the mauve accent (#c6a0f6) to match the
# vendored eza theme.yml (catppuccin's vivid palette uses blue for directories).
if command -v vivid >/dev/null; then
  _lscolors_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/ls_colors"
  if [[ ! -s "$_lscolors_cache" || "$(command -v vivid)" -nt "$_lscolors_cache" ]]; then
    vivid generate catppuccin-macchiato > "$_lscolors_cache"
  fi
  export LS_COLORS="$(<$_lscolors_cache):di=0;38;2;198;160;246"
  unset _lscolors_cache
fi
