# Run these commands if we're running inside Windows Subsystem for Linux v2

if [ -e /proc ] && [ $(grep -oE 'gcc version ([0-9]+)' /proc/version | awk '{print $3}') -gt 5 ] ; then
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

  ps ax | grep -q /usr/bin/kbfsfuse
  if [ $? -ne 0 ]; then
    setsid nohup /usr/bin/kbfsfuse -debug -log-to-file >/dev/null 2>&1 &
  fi
  ps ax | grep -q /usr/bin/keybase
  if [ $? -ne 0 ]; then
    setsid nohup /usr/bin/keybase --use-default-log-file --debug service >/dev/null 2>&1 &
  fi

#  setsid nohup /usr/bin/kbfsfuse -debug -log-to-file >/dev/null 2>&1 &
#  setsid nohup /usr/bin/keybase --use-default-log-file --debug service >/dev/null 2>&1 &
  # /usr/bin/keybase --debug --log-file /home/jeckhart/.cache/keybase/keybase.service.log service --chdir /home/jeckhart/.config/keybase --auto-forked
  # /mnt/wsl/docker-desktop/docker-desktop-proxy --distro-name Ubuntu --docker-desktop-root /mnt/wsl/docker-desktop
  wslfetch
fi
