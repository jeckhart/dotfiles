# WSL2-only (gated in .chezmoiignore). Sourced from ~/.zshenv, so it runs for every
# zsh, interactive or not, including the `zsh -c <cmd>` that Tailscale SSH (which
# serves inbound :22 here and never runs ~/.ssh/rc) uses for hc's `herdr-core connect`.
#
# ~/.ssh/agent.sock is the one agent path every shell, git, and systemd service
# uses. Its target follows whichever machine you last connected from:
#   inbound SSH with a forwarded agent (ssh, hc) -> that forwarded agent (Mac Touch ID)
#   local Windows terminal (WSL interop socket)  -> 1Password bridge (Windows Hello)
#   anything else (herdr panes, nested shells)   -> unchanged; bridge only if dangling
# herdr panes serve local and remote attaches alike, so they never choose.

# Repoint the link at $1 (a live socket) via rename, so concurrent shells never see
# it missing. zsh/files builtins: no fork, and nothing on stdout, which a `zsh -c`
# protocol command like herdr-core connect owns.
agent-link-point() {
  local link=$HOME/.ssh/agent.sock
  [[ -S $1 && ${link:A} != ${1:A} ]] || return 0
  zmodload -F zsh/files b:zf_ln b:zf_mv || return 0
  zf_ln -sf -- "$1" "$link.$$.tmp" && zf_mv -f -- "$link.$$.tmp" "$link"
}

# A disconnect deletes its forwarded socket, leaving the link dangling; fall back
# to the bridge. A stat only — a stale-but-present forwarded socket (client asleep)
# isn't detectable without an agent round-trip; the next connect or local terminal
# repoints it.
agent-link-heal() {
  [[ -S $HOME/.ssh/agent.sock ]] || agent-link-point "${XDG_RUNTIME_DIR:-/run/user/$UID}/ssh-agent.sock"
}

[[ -d $HOME/.ssh ]] || mkdir -m 700 "$HOME/.ssh"
if [[ -n $SSH_CONNECTION && -S $SSH_AUTH_SOCK && $SSH_AUTH_SOCK != $HOME/.ssh/agent.sock ]]; then
  agent-link-point "$SSH_AUTH_SOCK"
elif [[ -S $WSL_INTEROP ]]; then
  agent-link-point "${XDG_RUNTIME_DIR:-/run/user/$UID}/ssh-agent.sock"
else
  agent-link-heal
fi
export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
