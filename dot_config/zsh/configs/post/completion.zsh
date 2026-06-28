# load our own completion functions
fpath=($ZDOTDIR/completion "$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)

# completion cache lives under XDG cache; refresh if older than 24h
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
autoload -Uz compinit
if [[ -n ${_zcompdump}(#qN.mh+24) ]]; then
  compinit -d "$_zcompdump";
else
  compinit -C -d "$_zcompdump";
fi;
unset _zcompdump

# disable zsh bundled function mtools command mcd
# which causes a conflict.
compdef -d mcd
