[[ -z "$RUSTUP_HOME" ]] && RUSTUP_HOME="${HOME}/.rustup"
[[ -z "$CARGO_HOME" ]] && CARGO_HOME="${HOME}/.cargo"
export RUSTUP_HOME CARGO_HOME

[[ -d "${CARGO_HOME}" ]] && PATH="${PATH}:${CARGO_HOME}/bin"
