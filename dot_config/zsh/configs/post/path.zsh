# ensure dotfiles bin directory is loaded first

if [ -n "$HOMEBREW_PREFIX" ] && [ -e "$HOMEBREW_PREFIX/sbin" ]; then
  PATH="$HOME/.bin:$HOMEBREW_PREFIX/sbin:$PATH"
else
  PATH="$HOME/.bin:/usr/local/sbin:$PATH"
fi

# User-installed binaries (pipx, uv tool, etc.)
PATH="$HOME/.local/bin:$PATH"

export -U PATH
