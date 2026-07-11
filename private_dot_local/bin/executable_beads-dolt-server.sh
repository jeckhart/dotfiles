#!/bin/bash
# Launch the shared Dolt SQL server for beads (bd) issue tracking.
# Invoked by the launchd agent ~/Library/LaunchAgents/local.beads.dolt.plist.
# Writes beads-compatible PID/port files, then exec's dolt sql-server.
# Managed by chezmoi (~/.local/bin) so the daemon setup is reproducible.
SERVER_DIR="$HOME/.beads/shared-server"
echo $$ > "$SERVER_DIR/dolt-server.pid"
echo 3308 > "$SERVER_DIR/dolt-server.port"

# Force git non-interactive for any push the server itself runs (git+ssh), so a
# stalled connection/auth fails fast instead of hanging. github.com is routed
# over port 443 with a pinned 1Password key in ~/.ssh/config.
export GIT_TERMINAL_PROMPT=0

exec /opt/homebrew/opt/dolt/bin/dolt sql-server --config /opt/homebrew/etc/dolt/config.yaml
