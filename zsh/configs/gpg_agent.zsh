export GPG_TTY=$(tty)
gpg-connect-agent /bye
export SSH_AUTH_SOCK=$(/usr/local/MacGPG2/bin/gpgconf --list-dirs agent-ssh-socket)
