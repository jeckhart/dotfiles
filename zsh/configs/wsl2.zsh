# Run these commands if we're running inside Windows Subsystem for Linux v2

if [ $(grep -oE 'gcc version ([0-9]+)' /proc/version | awk '{print $3}') -gt 5 ] ; then
  export LC_ALL=en_US.UTF-8

  export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
  ss -a | grep -q $SSH_AUTH_SOCK
  if [ $? -ne 0 ]; then
    rm -f $SSH_AUTH_SOCK
    setsid nohup socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:$HOME/.ssh/wsl2-ssh-pageant.exe >/dev/null 2>&1 &
  fi
  export GPG_AGENT_SOCK=$HOME/.gnupg/S.gpg-agent
  ss -a | grep -q $GPG_AGENT_SOCK
  if [ $? -ne 0 ]; then
    rm -rf $GPG_AGENT_SOCK
    setsid nohup socat UNIX-LISTEN:$GPG_AGENT_SOCK,fork EXEC:"$HOME/.ssh/wsl2-ssh-pageant.exe --gpg S.gpg-agent" >/dev/null 2>&1 &
  fi

  wslfetch
fi
