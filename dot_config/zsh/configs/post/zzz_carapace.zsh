# carapace: fallback completer for the long tail of CLIs with no zsh-native
# completion (deno, cargo subcommands, ...). `zzz_` load order matters: this
# must run LAST, after completion.zsh (compinit must exist) and plugins.zsh
# (fzf-tab must already own the completion widget) and zoxide (native `_z`
# must already be bound before carapace's compdef list can be overridden below).
#
# Its init script is pre-generated at `chezmoi apply` time by regen-zsh-
# completions (never `eval "$(carapace ...)"` here — that's a subprocess on
# every shell). That init unconditionally `compdef`s every command it knows
# about, which would clobber zsh-native/brew-shipped/regen-zsh-completions
# completions for anything carapace also recognizes (gitleaks, lazygit, cargo,
# hx, ...). Snapshot the native mappings first and restore them after, so
# carapace only fills in commands nothing else already completes.
_carapace_init="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/carapace-init.zsh"
if [[ -r $_carapace_init ]]; then
  typeset -A _carapace_native_comps
  _carapace_native_comps=("${(@kv)_comps}")
  source "$_carapace_init"
  for _carapace_cmd in "${(@k)_carapace_native_comps}"; do
    _comps[$_carapace_cmd]="$_carapace_native_comps[$_carapace_cmd]"
  done
  unset _carapace_native_comps _carapace_cmd
fi
unset _carapace_init
