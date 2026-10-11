# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (cuts up to 90% of bash output)

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Token savings analytics
rtk gain --history    # Usage history with savings
rtk discover          # Analyze Claude Code history for missed savings
rtk proxy <cmd>       # Run command raw, no filtering (debug)
```

## Installation Verification

```bash
rtk --version         # Shows: rtk X.Y.Z
rtk gain              # Should work (not "command not found")
which rtk             # Confirms correct binary
```

## Hook-Based Usage

The Claude Code hook rewrites all other commands automatically.
Example: `git status` becomes `rtk git status` — transparent, no token overhead.

See CLAUDE.md for the full command reference.
