#!/bin/bash
# Launches RustRover with the ESP-IDF toolchain env set. A GUI-launched RustRover
# (Toolbox, Spotlight, `open`) never sources zsh's interactive startup, so
# configs/export-esp.zsh's exports never reach it — this script re-derives the
# same paths for that launch path. Bash equivalent of export-esp.zsh's zsh globs;
# keep the two in sync. Silently does nothing if the esp-nightly toolchain isn't
# installed (rustc +esp-nightly fails), same as export-esp.zsh's own guard.
set -euo pipefail

declare -a intellij_args=()
declare -- wait=""

for o in "$@"; do
	if [[ "$o" = "--wait" || "$o" = "-w" ]]; then
		wait="-W"
		o="--wait"
	fi
	if [[ "$o" =~ " " ]]; then
		intellij_args+=("\"$o\"")
	else
		intellij_args+=("$o")
	fi
done

if esp_root=$(rustc +esp-nightly --print sysroot 2>/dev/null); then
	shopt -s nullglob
	clang_lib_dirs=("$esp_root"/xtensa-esp32-elf-clang/*/esp-clang/lib)
	elf_bin_dirs=("$esp_root"/xtensa-esp-elf/*/xtensa-esp-elf/bin)
	shopt -u nullglob
	if [[ ${#clang_lib_dirs[@]} -gt 0 ]]; then
		clang_lib_dir="${clang_lib_dirs[-1]}"
		export LIBCLANG_PATH="$clang_lib_dir"
		export CLANG_PATH="${clang_lib_dir%/lib}/bin/clang"
	fi
	if [[ ${#elf_bin_dirs[@]} -gt 0 ]]; then
		export PATH="${elf_bin_dirs[-1]}:$PATH"
	fi
fi

open -na "$HOME/Applications/RustRover.app/Contents/MacOS/rustrover" $wait --args "${intellij_args[@]}"
