# Beads shared Dolt server: runbook

How these dotfiles stand up the host-global [Dolt](https://www.dolthub.com/) SQL server
that [beads](https://github.com/gastownhall/beads) (`bd`) uses in shared-server mode, on
both macOS and WSL2.

## Why a shared server

Beads normally starts a per-project embedded/per-repo dolt server. Shared-server mode
instead runs one server per host, on `127.0.0.1:3308`, serving every repo's database —
opt-in via `BEADS_DOLT_SHARED_SERVER=1` (`dot_config/zsh/configs/beads.zsh`, unconditional
on every platform) plus `dolt: {shared-server: true, auto-start: false}` in a project's
`.beads/config.yaml`. `auto-start: false` is load-bearing: it stops `bd` from launching its
own dolt instance against a data_dir a supervisor already owns.

## Layout

```text
~/.beads/shared-server/
  dolt/                       # data_dir
  dolt-config.yaml            # generated fresh on every start — never hand-edit
  dolt-server.log             # dolt's own stdout/stderr, opened+rotated by the wrapper
  dolt-server.log.1           # rotated-out predecessor (copy-truncate, backstop only)
  dolt-server.pid             # bd's discovery file
  dolt-server.port            # bd's discovery file (3308)
  dolt-server-launchd.log      # macOS only: launchd's own channel, pre-wrapper failures
```

## Which files own what

| File | Managed by | Notes |
| --- | --- | --- |
| `~/.local/bin/beads-dolt-server.sh` | chezmoi | Shared by both platforms. Probes for `dolt` across every known Homebrew prefix, generates `dolt-config.yaml`, writes the pid/port files, rotates the log, then `exec`s dolt so the supervisor's SIGTERM reaches it directly. |
| `~/Library/LaunchAgents/local.beads.dolt.plist` | chezmoi, macOS only | `KeepAlive`, `ExitTimeOut=60`. |
| `~/.config/systemd/user/beads-dolt.service` | chezmoi, WSL2 only | `Restart=always`, `TimeoutStopSec=60` — same intent as the plist. |
| `run_onchange_after_beads-dolt-server.sh` | chezmoi | Reloads the right supervisor whenever the wrapper, plist, or unit changes; warns and exits 0 if there's nothing to reload into (no GUI launchd domain, systemd disabled/unreachable). |
| `~/.beads/dolt/.beads-credential-key` | `bd`, per-repo, gitignored | See "New machine" below — **not** chezmoi-managed, machine-scoped. |

`dolt-config.yaml` is deliberately *not* a chezmoi template: `.beads/` (this repo's own
issue database) is in `.chezmoiignore`, so the wrapper is the only place it can be kept in
sync with the port bd expects.

## Operating it

```bash
# macOS
launchctl kickstart -k gui/$(id -u)/local.beads.dolt
launchctl print gui/$(id -u)/local.beads.dolt
tail -f ~/.beads/shared-server/dolt-server.log

# WSL2
systemctl --user restart beads-dolt
systemctl --user status beads-dolt
journalctl --user -u beads-dolt -n 50 -f

# Either platform
bd dolt status
bd dolt test
```

## New machine

`chezmoi apply` installs `dolt`/`beads` and starts the server; the data_dir is empty until
a repo initializes into it. Do **not** run a bare `bd init` against a shared server you
didn't just stand up yourself — see the credential-key hazard below. If this is a second
or later machine sharing the same beads project, copy
`.beads/dolt/.beads-credential-key` from a working machine/repo instead of generating a
fresh one.

## Known hazards (from upstream issues — read before debugging a "phantom" outage)

- **`bd init` / `bd dolt killall` can SIGKILL a dolt server they don't own**, taking down
  every other repo sharing it ([gastownhall/beads#2641][2641]). `dolt.auto-start: false`
  in `.beads/config.yaml` is the mitigation already in place for this repo; `Restart=
  always`/`KeepAlive` is the backstop that brings the server back regardless. Never run
  `bd dolt killall` on a host with other active repos without checking `bd dolt status`
  in each first.
- **The credential key is machine-scoped, not per-repo.** `~/.beads/dolt/
  .beads-credential-key` is a 32-byte file only `bd init` generates, and it's gitignored.
  On a new machine this creates a catch-22 (init needs it; only init makes it) — copy it
  from a working repo on the same machine rather than re-initializing.
- **`bd doctor` reporting other repos' databases as "phantom"** is known upstream noise in
  shared-server mode ([gastownhall/beads#2694][2694]), not evidence of actual corruption.
  Don't act on that suggestion (e.g. restarting the server) without other symptoms.
- **WSL2 only:** the WSL VM itself idles out when nothing holds it open, so the server
  runs "while WSL is up," not truly 24/7 — the same caveat `docs/radicle.md` documents for
  `radicle-node.service`. If gap-free availability across a Windows sleep/reboot cycle
  matters, that's a Windows-side keep-alive problem, deliberately out of dotfiles scope.

## Forward-looking

DoltHub/beads has an in-development **proxied-server mode** (`bd init --proxied-server`)
that manages the dolt server's lifecycle itself — start on demand, stop when idle — rather
than requiring a hand-managed supervisor. It's stated to eventually become the default and
replace shared-server mode, but is unreleased as of `bd 1.1.2` (what's installed today). If
it ships and proves solid, this whole supervisor layer (wrapper + plist/unit + reload
script) likely becomes unnecessary — don't invest further effort here beyond what's needed
today.

[2641]: https://github.com/gastownhall/beads/issues/2641
[2694]: https://github.com/gastownhall/beads/issues/2694
