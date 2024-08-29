export GPG_TTY=$(tty)
alias pinentry='pinentry-mac'

if [ ! -e /proc/version ] || $(uname -a | grep -v microsoft 2>&1 > /dev/null) ; then
  # [ $(grep -oE 'gcc version ([0-9]+)' /proc/version | awk '{print $3}') -le 5 ] ; then
  gpg-connect-agent /bye
  # export SSH_AUTH_SOCK=$(/usr/local/MacGPG2/bin/gpgconf --list-dirs agent-ssh-socket)
fi
