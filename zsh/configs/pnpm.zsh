# pnpm

case "$OSTYPE" in
  linux*)   
    export PNPM_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/pnpm"
    ;;
  darwin*)
    export PNPM_HOME="/Users/jeckhart/Library/pnpm"
    ;;
  win*)     echo "Windows" ;;
  msys*)    echo "MSYS / MinGW / Git Bash" ;;
  cygwin*)  echo "Cygwin" ;;
  bsd*)     echo "BSD" ;;
  solaris*) echo "Solaris" ;;
  *)        echo "unknown: $OSTYPE" ;;
esac

mkdir -p "${PNPM_HOME}"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

