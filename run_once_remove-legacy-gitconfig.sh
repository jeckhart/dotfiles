#!/bin/sh
# Remove the legacy rcm-managed ~/.gitconfig symlink so git falls back to the
# XDG location (~/.config/git/config). Only ever removes a symlink — never a
# real file — so a hand-written ~/.gitconfig is left untouched.
set -eu

if [ -L "$HOME/.gitconfig" ]; then
  rm -f "$HOME/.gitconfig"
  echo "removed legacy ~/.gitconfig symlink (git now uses ~/.config/git/config)"
fi
