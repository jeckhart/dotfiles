export GOPATH="${HOME}/projects/go"
[[ ! -d "$GOPATH" ]] && mkdir -p "$GOPATH"

export PATH=$PATH:$GOPATH/bin
if [ -n "$HOMEBREW_PREFIX" ] && [ -e "$HOMEBREW_PREFIX/opt/go/libexec/bin" ]; then
  export PATH=$PATH:$HOMEBREW_PREFIX/opt/go/libexec/bin
fi
