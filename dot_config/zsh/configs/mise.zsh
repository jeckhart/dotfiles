# mise: unified runtime version manager (replaces nodenv + pyenv + pyenv-virtualenv).
# Activation hooks chpwd/precmd like direnv; the Rust binary is ~5-15ms vs the old
# ~400ms nodenv+pyenv init that dominated startup. Global tool pins + settings live in
# ~/.config/mise/config.toml. Python venvs/packaging: use uv (per-project `uv venv`/`uv
# sync`, or a project mise.toml `_.python.venv` for auto-activation on cd).
command -v mise >/dev/null && eval "$(mise activate zsh)"
