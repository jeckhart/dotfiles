# kubectl aliases + completion. POST phase: `compdef` needs compinit (completion.zsh)
# to have run first. Replaces the oh-my-zsh kubectl plugin's alias/completion set.
#
# The completion script is cached (regenerated only when the kubectl binary is newer
# than the cache) so we don't pay a `kubectl completion zsh` subprocess every startup.
if command -v kubectl >/dev/null; then
  _kube_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/kubectl-completion.zsh"
  if [[ ! -s "$_kube_cache" || "$(command -v kubectl)" -nt "$_kube_cache" ]]; then
    kubectl completion zsh > "$_kube_cache"
  fi
  source "$_kube_cache"
  unset _kube_cache

  alias k=kubectl
  alias kgp='kubectl get pods'
  alias kgs='kubectl get svc'
  alias kaf='kubectl apply -f'
  alias kdel='kubectl delete'

  compdef k=kubectl   # make `k` completion-aware
fi
