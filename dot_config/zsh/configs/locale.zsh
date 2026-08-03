# Default locale. macOS ships en_US.UTF-8; on WSL2 run_once_install-zsh-apt.sh generates it.
# Until it exists, fall back to C.UTF-8 (always built into glibc) so subshells don't warn.
if locale -a 2>/dev/null | grep -qiE '^en_US\.utf-?8$'; then
  export LANG=en_US.UTF-8
else
  export LANG=C.UTF-8
fi
