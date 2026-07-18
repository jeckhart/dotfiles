
# Ensure Homebrew is initialized for ANY interactive shell, not just login shells.
# Login shells get `brew shellenv` from ~/.config/zsh/.zprofile, but tools that spawn an
# interactive *non-login* shell (e.g. herdr) skip .zprofile — leaving brew, and everything
# that depends on it (mise, starship), off PATH. Mirror .zprofile's discovery ladder here,
# guarded so it's a no-op when a login shell already ran it.
if ! command -v brew >/dev/null 2>&1; then
  for _brew in \
    "$HOMEBREW_PREFIX/bin/brew" \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew; do
    if [ -x "$_brew" ]; then
      eval "$("$_brew" shellenv)"
      break
    fi
  done
  unset _brew
fi
export HOMEBREW_PREFIX

