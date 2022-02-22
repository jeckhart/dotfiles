
# Homebrew goes somewhere different on the M1 Macs and newer, make sure we have
# it in the path
HOMEBREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
export HOMEBREW_PREFIX
if [ -z "$HOMEBREW_PREFIX" ] || [ -z "$HOMEBREW_REPOSITORY" ]; then
  UNAME_MACHINE="$(/usr/bin/uname -m)"
  if [[ "$UNAME_MACHINE" == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
  else
    HOMEBREW_PREFIX="/usr/local"
  fi
  export HOMEBREW_PREFIX
  export PATH="$HOMEBREW_PREFIX/bin:$PATH"
fi

