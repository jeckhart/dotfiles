# Radicle: private mesh, 1Password-driven, deployed by chezmoi

How these dotfiles stand up any macOS/WSL2 workstation as a node in our private
[Radicle](https://radicle.dev) mesh (Heartwood, v1.9+). Supersedes the original
hand-rolled runbook (`radicle-private-seed-runbook.md` era): node details now live in
1Password as the single source of truth, and everything else is rendered from it at
`chezmoi apply`.

> Domain note: the project moved `radicle.xyz` → `radicle.dev` (install script, apt
> repo, docs) and its public bootstrap seeds to `*.radicle.network` in release 1.9.0.

## Architecture

```
laptop (macOS)  <------ Tailscale mesh ------>  desktop (WSL2)
        \                                           /
         \                                         /
          ------->  pi seed (Docker on HAOS)  <----
                    always-on relay, allow-listed only
```

(Real node names, addresses, and identities live only in 1Password — this public
repo deliberately contains no actual machine details.)

- **One Radicle identity per live device** (still a protocol requirement). Each logical
  node's identity is *durable*: the full keypair + passphrase are backed up in its
  1Password item, so a machine rebuild restores the same identity (no allow-list churn).
- **1Password is the roster.** Templates enumerate `radicle-node-*` items in the vault
  at apply time to build every node's `connect` list. Adding a node = enrolling it
  (below); every other machine picks it up on its next `chezmoi apply` (which also
  restarts its node).
- **Fully private:** public bootstrap seeds are only injected when `node.connect` is
  empty and the address DB is empty — our config always sets `connect`, plus
  `preferredSeeds: []` and `seedingPolicy: block`. Crucially, `peers: static` limits
  dialing to the `connect` list: without it, addresses gossip-learned via the Pi (which
  talks to the public network) get dialed under the default dynamic peering — observed
  live during rollout. Workstations bind their Tailscale IP only, so the node port is
  unreachable from café/hotel LANs.
- The **Pi seed** stays separately managed (Portainer/Docker on HAOS, see the legacy
  runbook for its compose setup) but is registered in 1Password like any other node, and
  should stay `--allow`-listed only on private repos — a relay, never a delegate.

## 1Password schema (vault: whatever the `opVault` chezmoi prompt was answered with)

**`radicle-node-<name>`** — one per node; `<name>` is the machine's lowercased short
hostname (that's how a machine recognizes itself; the Pi's is just `pi`):

| field             | notes                                                                                                          |
| ----------------- | -------------------------------------------------------------------------------------------------------------- |
| `alias`           | node alias (usually = name; may differ for legacy nodes)                                                       |
| `nid`             | node ID (`z6Mk…`)                                                                                              |
| `did`             | `did:key:z6Mk…` — used for `rad id update --allow/--delegate`                                                  |
| `address`         | Tailscale IPv4                                                                                                 |
| `port`            | `8776`                                                                                                         |
| `passphrase`      | key passphrase (concealed)                                                                                     |
| `private-key-b64` | base64 of `$RAD_HOME/keys/radicle`, byte-exact (concealed)                                                     |
| `public-key`      | contents of `radicle.pub`                                                                                      |
| `listen-address`  | *optional* — bind address when `address` isn't bindable in-distro (WSL2 NAT + host-side Tailscale → `0.0.0.0`) |

**`radicle-mesh`** — one item; a `repos` section maps repo name → RID. Every enrolled
node seeds every RID listed there (`run_onchange_after_radicle-2-seed`); edit the item
and re-apply to change replication. Working copies are always manual (`rad clone`).

## What chezmoi deploys (when this host's item exists)

| target                                                                          | source                                     | purpose                                                             |
| ------------------------------------------------------------------------------- | ------------------------------------------ | ------------------------------------------------------------------- |
| `~/.radicle/config.json`                                                        | `.chezmoitemplates/radicle/config.json`    | full node config from the vault roster                              |
| `~/.config/radicle/node.env` (0600)                                             | `dot_config/radicle/private_node.env.tmpl` | `RAD_HOME` + `RAD_PASSPHRASE` for the supervisor                    |
| `~/.config/zsh/configs/radicle.zsh`                                             | template                                   | `RAD_PASSPHRASE` for the CLI (1P SSH agent rejects `ssh-add`)       |
| `~/.bin/rad-bootstrap`                                                          | `dot_bin/`                                 | enrollment/restore tool (deployed even when un-enrolled)            |
| `~/.bin/rad-clone-public`                                                       | `dot_bin/`                                 | clone from the public network without un-privatizing the node       |
| `~/.bin/radicle-node-wrapper` + `~/Library/LaunchAgents/dev.radicle.node.plist` | macOS only                                 | always-on node (KeepAlive; logs: `~/Library/Logs/radicle-node.log`) |
| `~/.config/systemd/user/radicle-node.service`                                   | WSL2 only                                  | always-on node (`Restart=always`)                                   |

Gating lives in `.chezmoiignore` via `.chezmoitemplates/radicle/enabled`: item present →
deploy; item absent → skip radicle targets; 1Password locked → **fail the whole run**
(refuses to silently un-manage). Supervisors exec `radicle-node --force` directly (the
pattern Radicle's own systemd unit uses); `rad node start --foreground` is for
interactive debugging only — under a supervisor it would own the PID instead of the node.

## Enrolling a machine (bootstrap)

```bash
chezmoi apply       # installs radicle (brew/apt); host un-enrolled → only rad-bootstrap lands
rad-bootstrap       # creates identity (rad auth) + writes radicle-node-<hostname> to 1P
                    # …or restores keys from 1P if the item already exists (rebuild case)
chezmoi apply       # renders config/env/service; node starts; seeding policies apply
```

Two applies are inherent: chezmoi evaluates **all** templates before running any script,
so the item `rad-bootstrap` creates is only visible to the next apply. After enrolling,
from any existing delegate machine, allow the new DID on each private repo:

```bash
rad id update --allow did:key:<new-node-did> --title "Allow <name>"
```

WSL2 prerequisites: Tailscale running *inside* the distro, systemd enabled
(`[boot] systemd=true` in `/etc/wsl.conf`), Windows `op.exe` reachable via interop.
Caveat: the WSL VM idles out when nothing holds it open — the node runs "while WSL is
up". If true 24/7 matters, add a Windows scheduled task that keeps a `wsl.exe` session
alive (deliberately out of dotfiles scope).

WSL2 + host-side Tailscale caveat: if Tailscale runs on the *Windows host* instead of
in-distro (NAT networking mode), the host's Tailscale IP is not bindable inside the
distro — set the item's optional `listen-address` field to `0.0.0.0` so the node binds
locally while `address` keeps advertising the host's Tailscale IP. Such a node is
**outbound-only**: nothing can dial in through the Windows host without a portproxy or
WSL mirrored networking, so it syncs by dialing the Pi and other peers. Items without
`listen-address` render `listen = externalAddresses` as before.

## Conventions

- **Delegates vs allow-list:** machines you author from get `--delegate` (threshold 1);
  the Pi (and any pure relay) gets `--allow` only. Both take DIDs, not NIDs.
- **Identity changes need a MAJORITY of delegates** — the doc's `threshold` field does
  NOT govern this (it's for canonical branch refs). With N delegates, a `rad id update`
  revision only lands once >N/2 delegate votes point at it (verified in heartwood
  `radicle/src/cob/identity.rs`).
- **One active identity revision at a time.** Votes are tracked by a per-delegate
  *head* pointer that moves when you author **or** accept a revision. Authoring a new
  revision while yours is still pending silently withdraws your vote from the old one;
  `rad id redact` does **not** restore it; and you can't re-vote for your own revision
  (`rad id accept` fails — your authorship signature already counts, and duplicate
  verdicts are rejected). Author-then-redact-a-competitor therefore deadlocks the
  original below quorum permanently. Escape hatch: reissue the same change as a fresh
  revision from a **different** delegate and have the original author accept that one;
  the stuck revision goes stale automatically on acceptance (hit live, 2026-07-04).
- **New repo:** `rad init --private`, add delegates/allows, then add its RID to the
  `radicle-mesh` item — every node starts seeding it on next apply.
- **Retiring a node:** delete its 1P item (other machines drop it from `connect` on next
  apply), `--disallow` its DID from private repos, and wipe its `$RAD_HOME`.
- **Renaming a host:** the item title must match the new lowercased hostname; rename the
  item, re-apply.

## Cloning a public repository

The mesh is deliberately **fully private** (see above): `preferredSeeds: []`,
`seedingPolicy: block`, `peers: static`. Plain `rad clone <public-rid>` therefore fails
with `no candidate seeds were found to fetch from` — the node has no public seed and no
routing entry for a RID outside our mesh. That's by design, not a bug.

To clone a public repo without weakening the always-on node's privacy, use
`rad-clone-public <rid>`. It:

1. opens a **runtime-only** `rad node connect` to a public seed (never written to
   `config.json`),
2. clones with `rad clone --seed <nid>`,
3. bounces the node so the transient public connection drops and the node reloads the
   private-only config.

```bash
rad-clone-public rad:z4L8L9ctRYn2bcPuUT4GRz7sggG1v            # clone, then re-privatize
rad-clone-public rad:z4L8L9ctRYn2bcPuUT4GRz7sggG1v --stay     # keep the seed link this session
rad-clone-public <rid> --seed <nid@host:port>                 # override the default seed
RAD_PUBLIC_SEED=<nid@host:port> rad-clone-public <rid>        # same, via env var
```

Default seed is `seed.radicle.garden` (verified live via its `/api/v1/node` HTTP
endpoint). Use `--stay` when the repo you're building depends on other rad repos hosted
on the same public seed — the link then survives for the rest of the node's current
session (subsequent `rad clone`/`rad sync` calls can reuse it), and drops automatically
on the next node restart/reboot regardless, since `config.json` was never modified.

Tradeoff: while connected, that one public seed can see this node's NID and (per its
`--scope`) query its inventory. The default (non-`--stay`) mode bounds that exposure to
the duration of the clone.

## Troubleshooting

- **"no candidate seeds were found to fetch from"** — expected for public RIDs; this
  mesh doesn't carry public seeds by design. Use `rad-clone-public <rid>` instead of
  `rad clone` (see "Cloning a public repository" above).
- **"Target not met: could not fetch…"** — check `rad node status` on both ends (really
  *connected*, not just gossip-known); check the repo's allow-list has this node's DID;
  check `tailscale ping <peer>` below Radicle. (The historical "not configured to listen"
  root cause is designed out — config.json always sets `node.listen`.)
- **Node won't start after crash loop** — see `~/Library/Logs/radicle-node.log` (macOS)
  or `journalctl --user -u radicle-node` (WSL2). "No identity" → run `rad-bootstrap`.
- **`rad` prompts for passphrase / "invalid passphrase"** — a stale `RAD_PASSPHRASE` in
  the shell (another node's, or pre-rotation). `exec zsh` to reload the rendered value.
  `rad-bootstrap` unsets it before `rad auth` for exactly this reason.
- **Identity revision stuck "active"/"Quorum no" although every delegate shows ✓** —
  the ✓ marks are recorded verdicts, but quorum counts delegate *heads*, and a head
  only points at one revision. Some delegate's head has moved on (they authored a later
  revision, even a redacted one). `rad cob log --type xyz.radicle.id --object <cob-id>
  --repo <rid>` shows each delegate's latest op. Fix: see "One active identity revision
  at a time" above.
- **chezmoi apply fails with "1Password is locked"** — intended; unlock and re-run.
- **Config sanity:** `rad config` parses and prints the effective config; `rad self`
  shows the identity; compare with the 1P item.

## Cheat sheet

```
rad self --did / --nid            # this node's identity
rad node status                   # peer connections
rad .                             # current repo's RID
rad ls                            # repos this node knows
rad id update --allow <did>       # grant private-repo read access
rad id update --delegate <did> --threshold N   # grant identity authorship
rad seed <rid> --scope followed   # replicate without a working copy
rad clone <rid>                   # replicate + working copy
rad-clone-public <rid>            # clone a public repo, then re-privatize
rad sync --fetch                  # pull from connected peers
rad node start --foreground       # debug run (supervisor normally owns the node)
```
