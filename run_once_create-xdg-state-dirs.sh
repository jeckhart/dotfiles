#!/bin/sh
# Pre-create XDG dirs that zsh writes into (history, completion cache,
# generated completions) so the first interactive shell after apply doesn't
# fail to persist them.
set -eu

mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/less"
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/python"
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/node"
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions"
