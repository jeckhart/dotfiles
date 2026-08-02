#!/bin/sh
# Bootstrap TPM (Tmux Plugin Manager)
# Runs once — chezmoi tracks the hash of this script
set -eu
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
	git clone --depth 1 --branch v3.1.0 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
