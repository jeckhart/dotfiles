# Run these commands if we're running inside Windows Subsystem for Linux v2

if [ -e /proc ] && $(grep -oE 'WSL2' /proc/version >/dev/null 2>&1 ) ; then
  export LC_ALL=en_US.UTF-8

  # Point X11 apps at the Windows host's X server (VcXsrv/X410 over the WSL2 NAT)
  export DISPLAY="$(grep nameserver /etc/resolv.conf | awk '{print $2; exit;}'):0.0"

  SHARED_CONFIG=/mnt/wsl/shared
  mkdir -p "$SHARED_CONFIG"

  export SSH_AUTH_SOCK="$SHARED_CONFIG/S.ssh-agent.sock"
  ss -a | grep -q "$SSH_AUTH_SOCK"
  if [ $? -ne 0 ]; then
    rm -f "$SSH_AUTH_SOCK"
    setsid nohup socat UNIX-LISTEN:"$SSH_AUTH_SOCK",fork EXEC:$HOME/.ssh/wsl2-ssh-pageant.exe >/dev/null 2>&1 &
  fi

  wslfetch
fi
