if [ -n "$HOMEBREW_PREFIX" ]; then
  BREWPATH="$HOMEBREW_PREFIX/bin/brew"
fi

[ ! -e "$BREWPATH" ] && BREWPATH='/opt/homebrew/bin/brew'
[ ! -e "$BREWPATH" ] && BREWPATH='/usr/local/bin/brew'
[ ! -e "$BREWPATH" ] && BREWPATH='/home/linuxbrew/.linuxbrew/bin/brew'

[ -e "$BREWPATH" ] && eval $("$BREWPATH" shellenv)

