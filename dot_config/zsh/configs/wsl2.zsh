# Run these commands if we're running inside Windows Subsystem for Linux v2

if [ -e /proc ] && $(grep -oE 'WSL2' /proc/version >/dev/null 2>&1 ) ; then
  export LC_ALL=en_US.UTF-8

  # Point X11 apps at the Windows host's X server (VcXsrv/X410 over the WSL2 NAT)
  export DISPLAY="$(grep nameserver /etc/resolv.conf | awk '{print $2; exit;}'):0.0"

  # 1Password's SSH agent (a Windows named pipe) is bridged to a Unix socket by
  # the ssh-agent-bridge systemd user unit (socat + npiperelay), so native
  # ssh/ssh-add/git/radicle all work — no ssh.exe alias needed. The same path is
  # exported to systemd services via ~/.config/environment.d/ssh_auth_sock.conf.
  export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.sock"

  # No native op on this box; the Windows CLI (on $PATH via interop) talks
  # straight to the Windows 1Password app, and chezmoi itself uses op.exe.
  alias op='op.exe'

  wslfetch
fi
