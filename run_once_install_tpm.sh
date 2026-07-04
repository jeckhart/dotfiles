#!/bin/sh
# Bootstrap TPM (Tmux Plugin Manager)
# Runs once — chezmoi tracks the hash of this script
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
	git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
