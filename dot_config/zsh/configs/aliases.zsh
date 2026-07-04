# Shell aliases (loaded by _load_settings). There is no .zshrc.local seam —
# machine-generic config lives here; secrets come from 1Password templates.

# Unix
alias ln="ln -v"
alias mkdir="mkdir -p"
# hwatch: watch with history + diff highlighting (plain `command watch` for the original)
command -v hwatch >/dev/null && alias watch='hwatch'

# eza (modern ls). `cat` is deliberately left as real cat — bat is for previews/MANPAGER.
if command -v eza >/dev/null; then
  # eza does NOT auto-read ~/.config/eza/theme.yml; without EZA_CONFIG_DIR it falls
  # back to LS_COLORS (16-color). Set it so the Catppuccin Macchiato theme.yml wins.
  export EZA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/eza"
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -la --icons --group-directories-first --git --header'
  alias lt='eza --tree --level=2 --icons'
else
  alias ll="ls -al"
fi

# git — a small hand-picked set (not oh-my-zsh's 191).
alias gst='git status'
alias gco='git checkout'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gc='git commit -v'
alias gca='git commit -av'
alias glog='git log --oneline --decorate --graph'

# Directory stack (AUTO_PUSHD in options.zsh): `d` lists, `1`-`9` jump by index.
alias d='dirs -v'
for _i ({1..9}) alias "$_i"="cd +${_i}"; unset _i
# single-quoted so they resolve $EDITOR/$VISUAL at call time, regardless of load order
alias e='$EDITOR'
alias v='$VISUAL'

# Ruby / Rails
alias b="bundle"
alias s="rspec"
alias migrate="bin/rails db:migrate db:rollback && bin/rails db:migrate db:test:prepare"

# Pretty-print the PATH
alias path='echo $PATH | tr -s ":" "\n"'

# Easier navigation
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias -- -="cd -"

# AWS: clear all session/profile env in one shot
alias unsetaws='unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_EXPIRATION AWS_SESSION_TOKEN AWS_PROFILE AWS_REGION AWS_DEFAULT_REGION'

# Prefer neovim when available
if type nvim > /dev/null 2>&1; then
  alias vim='nvim'
fi
