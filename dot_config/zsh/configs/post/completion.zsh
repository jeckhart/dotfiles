# load our own completion functions + plugin-provided ones. zsh-completions is
# managed by sheldon, but its fpath dir must be present BEFORE compinit (sheldon
# sources in post/plugins.zsh, which runs after this) — so add its clone dir here.
_zsh_completions_src="${XDG_DATA_HOME:-$HOME/.local/share}/sheldon/repos/github.com/zsh-users/zsh-completions/src"
fpath=($ZDOTDIR/completion ${_zsh_completions_src}(N) "$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
unset _zsh_completions_src

# completion cache lives under XDG cache; refresh if older than 24h
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
autoload -Uz compinit
if [[ -n ${_zcompdump}(#qN.mh+24) ]]; then
  compinit -d "$_zcompdump";
else
  compinit -C -d "$_zcompdump";
fi;
unset _zcompdump

# colorize completion menus with LS_COLORS (Catppuccin Macchiato; set in color.zsh).
# fzf-tab consumes the same LS_COLORS for its completion popup.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# disable zsh bundled function mtools command mcd
# which causes a conflict.
compdef -d mcd
