export GOPATH="${HOME}/projects/go"
[[ ! -d "$GOPATH" ]] && mkdir -p "$GOPATH"

if [ -n "$HOMEBREW_PREFIX" ] && [ -e "$HOMEBREW_PREFIX" ]; then
  export PATH=$PATH:$GOPATH/bin:$HOMEBREW_PREFIX/opt/go/libexec/bin
else
  export PATH=$PATH:$GOPATH/bin:/usr/local/opt/go/libexec/bin
fi
