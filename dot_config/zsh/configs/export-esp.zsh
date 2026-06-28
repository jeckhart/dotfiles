# ESP32 Rust toolchain (espup-installed under the rustup `esp-nightly` toolchain).
# Derived dynamically so toolchain version bumps don't break paths, and so non-ESP
# shells/machines (no esp-nightly toolchain) are left untouched.
if esp_root=$(rustc +esp-nightly --print sysroot 2>/dev/null); then
  clang_lib=("$esp_root"/xtensa-esp32-elf-clang/*/esp-clang/lib(N))
  [[ -n "$clang_lib" ]] && export LIBCLANG_PATH="${clang_lib[-1]}"
  elf_bin=("$esp_root"/xtensa-esp-elf/*/xtensa-esp-elf/bin(N))
  [[ -n "$elf_bin" ]] && export PATH="${elf_bin[-1]}:$PATH"
  unset clang_lib elf_bin
fi
unset esp_root
