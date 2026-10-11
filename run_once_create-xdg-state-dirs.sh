#!/bin/sh
# Pre-create XDG dirs that zsh writes into (history, completion cache,
# generated completions) so the first interactive shell after apply doesn't
# fail to persist them.
set -eu

# Mirror dot_zshenv's default (${XDG_CACHE_HOME:-...}: ~/Library/Caches on macOS,
# ~/.cache elsewhere) by hand — this script runs standalone under `chezmoi apply`,
# not sourced from a zsh startup file, so it can't just read dot_zshenv's result.
case "$(uname -s)" in
Darwin) _default_cache_home="$HOME/Library/Caches" ;;
*) _default_cache_home="$HOME/.cache" ;;
esac

mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/less"
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/python"
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/node"
mkdir -p "${XDG_CACHE_HOME:-$_default_cache_home}/zsh"
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions"
