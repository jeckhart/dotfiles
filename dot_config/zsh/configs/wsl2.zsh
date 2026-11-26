# Run these commands if we're running inside Windows Subsystem for Linux v2

if [ -e /proc ] && $(grep -oE 'WSL2' /proc/version >/dev/null 2>&1 ) ; then
  # Route $BROWSER-aware tools (gh, jupyter, dev servers) and `open` to the Windows
  # default handler via wsl-open (~/.bin, wraps explorer.exe) — but only when WSL
  # interop is live in THIS shell. wsl-open needs interop to launch explorer.exe.
  # sshd-spawned sessions don't inherit $WSL_INTEROP, so we leave both unset there
  # rather than point them at a wsl-open that would fail (and would open a browser
  # on this host, not the ssh client).
  if [ -S "$WSL_INTEROP" ]; then
    export BROWSER=wsl-open
    alias open=wsl-open
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

  # SSH_AUTH_SOCK routing lives in ~/.config/zsh/agent-link.zsh (sourced from
  # .zshenv). Long-lived herdr panes re-check the link at each prompt so a remote
  # disconnect falls back to the 1Password bridge.
  if (( $+functions[agent-link-heal] )); then
    autoload -Uz add-zsh-hook && add-zsh-hook precmd agent-link-heal
  fi

  # No native op on this box; the Windows CLI (on $PATH via interop) talks
  # straight to the Windows 1Password app, and chezmoi itself uses op.exe.
  alias op='op.exe'
fi
