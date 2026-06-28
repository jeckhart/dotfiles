# Shell aliases (loaded by _load_settings). Machine-local aliases that must stay
# out of version control belong in ~/.config/zsh/.zshrc.local instead.

# Unix
alias ll="ls -al"
alias ln="ln -v"
alias mkdir="mkdir -p"
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
