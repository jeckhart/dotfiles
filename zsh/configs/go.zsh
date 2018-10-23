export GOPATH="${HOME}/projects/go"
[[ ! -d "$GOPATH" ]] && mkdir -p "$GOPATH"
export PATH=$PATH:$GOPATH/bin:/usr/local/opt/go/libexec/bin
