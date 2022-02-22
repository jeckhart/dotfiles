# ensure dotfiles bin directory is loaded first

if [ -n "$HOMEBREW_PREFIX" ] && [ -e "$HOMEBREW_PREFIX/sbin" ]; then
  PATH="$HOME/.bin:$HOMEBREW_PREFIX/sbin:$PATH"
else
  PATH="$HOME/.bin:/usr/local/sbin:$PATH"
fi


# Try loading ASDF from the regular home dir location
if [ -f "$HOME/.asdf/asdf.sh" ]; then
  . "$HOME/.asdf/asdf.sh"
elif [ -n "$HOMEBREW_PREFIX" ] &&
  [ -e "$HOMEBREW_PREFIX" ] &&
  [ -f "$HOMEBREW_PREFIX/opt/asdf/asdf.sh" ]; then
  . "$HOMEBREW_PREFIX/opt/asdf/asdf.sh"
elif which brew >/dev/null &&
  BREW_DIR="$(dirname `which brew`)/.." &&
  [ -f "$BREW_DIR/opt/asdf/asdf.sh" ]; then
  . "$BREW_DIR/opt/asdf/asdf.sh"
fi

# mkdir .git/safe in the root of repositories you trust
PATH=".git/safe/../../bin:$PATH"

export -U PATH
