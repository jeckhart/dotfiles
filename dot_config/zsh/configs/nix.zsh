# Nix coexistence seam — every line is a no-op on machines without nix.
# Nix remains installed for per-project flakes; on work machines a slim
# nix-darwin/home-manager layer manages work-specific config.

# Multi-user nix daemon (PATH, NIX_PROFILES, etc.)
[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# Home-manager session variables (work layer publishes env vars this way,
# since chezmoi owns the shell and HM's own zsh plumbing is disabled).
[ -f "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" ] && . "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
[ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ] && . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
