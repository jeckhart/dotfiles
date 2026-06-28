# GNU userland first on PATH (replaces the oh-my-zsh gnu-utils plugin). Puts the
# Homebrew gnubin shims ahead of the BSD tools so `sed`/`date`/`grep`/`tar`/`awk`
# resolve to the GNU versions under their normal names (no g-prefix needed).
# `typeset -gU path` keeps PATH de-duplicated. NOTE: -g is REQUIRED — configs are
# sourced inside the _load_settings function (see ~/.config/zsh/.zshrc), so a plain
# `typeset` would create a function-local `path` and clobber PATH for the rest of load.
if [ -n "$HOMEBREW_PREFIX" ]; then
  typeset -gU path
  for _gnupkg in coreutils findutils gnu-sed gnu-tar grep gawk; do
    _gnubin="$HOMEBREW_PREFIX/opt/$_gnupkg/libexec/gnubin"
    [ -d "$_gnubin" ] && path=("$_gnubin" $path)
  done
  unset _gnupkg _gnubin
  export PATH
fi
