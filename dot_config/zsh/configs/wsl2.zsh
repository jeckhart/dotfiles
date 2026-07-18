# Run these commands if we're running inside Windows Subsystem for Linux v2

if [ -e /proc ] && $(grep -oE 'WSL2' /proc/version >/dev/null 2>&1 ) ; then
  export LC_ALL=en_US.UTF-8

  # Route $BROWSER-aware tools (gh, jupyter, dev servers) to the Windows default
  # browser via wslview (wslu) — but only when WSL interop is live in THIS shell.
  # wslview needs interop to launch the .exe. sshd-spawned sessions don't inherit
  # $WSL_INTEROP, so we leave BROWSER unset there rather than point it at a wslview
  # that would fail (and would open a browser on this host, not the ssh client).
  if [ -S "$WSL_INTEROP" ]; then
    export BROWSER=wslview
  fi

  # X server for GUI apps. Prefer WSLg's native server (:0 via /tmp/.X11-unix/X0
  # on Windows 11 / recent WSL); only fall back to a Windows-host X server over the
  # WSL2 NAT (VcXsrv/X410) when WSLg is absent. Never point DISPLAY at a dead X
  # server: xdg-utils' detectDE runs `xprop -root`, which blocks on an unreachable
  # DISPLAY and stalls xdg-open / xdg-mime / xdg-settings indefinitely.
  if [ -S /tmp/.X11-unix/X0 ]; then
    export DISPLAY=:0
  else
    export DISPLAY="$(grep nameserver /etc/resolv.conf | awk '{print $2; exit;}'):0.0"
  fi

  # SSH_AUTH_SOCK indirection: remote/herdr sessions reach a forwarded 1Password
  # agent (Hello runs on the connecting machine, not this host). Every shell uses the
  # stable ~/.ssh/agent.sock link; its target follows context:
  #   inbound SSH with a live forwarded agent -> that agent
  #   otherwise, or a dead link -> the 1Password bridge socket
  # herdr panes inherit the constant link path, so a reconnect that repoints the link
  # is picked up without any herdr config.
  [ -d "$HOME/.ssh" ] || mkdir -p -m 700 "$HOME/.ssh"
  _agent_link="$HOME/.ssh/agent.sock"
  _agent_bridge="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.sock"
  if [ -n "$SSH_CONNECTION" ] && [ -S "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$_agent_link" ]; then
    ln -sf "$SSH_AUTH_SOCK" "$_agent_link"      # remote: track this connection's forwarded agent
  elif [ ! -S "$_agent_link" ] && [ -S "$_agent_bridge" ]; then
    ln -sf "$_agent_bridge" "$_agent_link"      # local / self-heal a dead link: 1P bridge
  fi
  export SSH_AUTH_SOCK="$_agent_link"
  unset _agent_link _agent_bridge

  # No native op on this box; the Windows CLI (on $PATH via interop) talks
  # straight to the Windows 1Password app, and chezmoi itself uses op.exe.
  alias op='op.exe'

  wslfetch
fi
