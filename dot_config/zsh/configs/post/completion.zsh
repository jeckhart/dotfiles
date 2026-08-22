# load our own completion functions + plugin-provided ones. zsh-completions is
# managed by sheldon, but its fpath dir must be present BEFORE compinit (sheldon
# sources in post/plugins.zsh, which runs after this) — so add its clone dir here.
# ${_gen_completions} holds the functions regen-zsh-completions writes at `chezmoi
# apply` time (gitleaks, lazygit, cargo, ...) — see run_onchange_after_generate-
# completions.sh.tmpl. `-gU` dedupes: brew's shellenv already exports FPATH, so a
# nested shell inherits a built fpath and this prepend would otherwise double up
# every entry on every level of nesting.
typeset -gU fpath FPATH
_zsh_completions_src="${XDG_DATA_HOME:-$HOME/.local/share}/sheldon/repos/github.com/zsh-users/zsh-completions/src"
_gen_completions="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions"
fpath=($ZDOTDIR/completion ${_gen_completions}(N) ${_zsh_completions_src}(N) ${HOMEBREW_PREFIX:+"$HOMEBREW_PREFIX/share/zsh/site-functions"} $fpath)
unset _zsh_completions_src _gen_completions

# completion cache lives under XDG cache. Always -C (trust the dump, skip the
# fpath rescan + compaudit): regen-zsh-completions deletes the dump whenever it
# changes anything, so a stale/missing dump self-heals on the next shell (~450ms,
# one-time) instead of paying a periodic full rescan (~430ms) regardless of
# whether anything changed.
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
autoload -Uz compinit
compinit -C -d "$_zcompdump"
unset _zcompdump

# zcompcache: cache-using completers (e.g. _cargo, _git) write precomputed
# completion data here instead of the non-XDG default ~/.zcompcache.
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# colorize completion menus with LS_COLORS (Catppuccin Macchiato; set in color.zsh).
# fzf-tab consumes the same LS_COLORS for its completion popup.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# disable zsh bundled function mtools command mcd
# which causes a conflict.
compdef -d mcd
