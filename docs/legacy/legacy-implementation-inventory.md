# Legacy implementation inventory

**Status:** Historical documentation for M0-001  
**Date:** 2026-09-06  
**Updated:** 2026-09-07  
**Source issue:** [#2](https://github.com/AutismUp/aumc_server/issues/2) (`M0-001`)  
**Retirement authorization:** M8-004 only, after the remaining questions below are answered or waived

This document records the behavior of the current Vagrant, Google Cloud, and Minecraft Server Manager (MSM) files. Those files are historical inputs, not the target architecture. They must remain in the repository until M8-004 authorizes retirement.

Do not use these scripts to provision production. They target Google Cloud, open broad firewall rules, download mutable MSM files through shortened URLs, and install the legacy MSM/`screen` runtime.

Replacement architecture:

- [`docs/architecture/minecraft-server-manager-plan.md`](../architecture/minecraft-server-manager-plan.md)
- [`docs/adr/0001-embed-pocketbase-framework.md`](../adr/0001-embed-pocketbase-framework.md)
- [`docs/adr/0002-instance-owned-world-storage.md`](../adr/0002-instance-owned-world-storage.md)
- [`PLAN.md`](../../PLAN.md)

## Tracked legacy files

| File | Purpose | Dependencies | Execution role |
|---|---|---|---|
| [`Vagrantfile`](../../Vagrantfile) | Local VirtualBox development VM that installs Java, MSM, and an unpinned BuildTools JAR | Vagrant, VirtualBox, `ubuntu/focal64` box, outbound HTTPS | Local developer environment |
| [`01-create-server.sh`](../../01-create-server.sh) | Google Cloud VM, reserved IP, tags, and 0.0.0.0/0 firewall rules | `gcloud` CLI, project `autismupminecraft`, Compute Engine permissions | Production-style host create (GCP) |
| [`02-setup-server.sh`](../../02-setup-server.sh) | Host bootstrap: packages, MSM, BuildTools download, and `auoperator` account | Root/`sudo` on Ubuntu, outbound HTTPS, `wget`, `curl`, `git` | Production-style host setup (GCP) |
| [`.gitignore`](../../.gitignore) | Ignores Vagrant local state only | None | Repository hygiene |

No other MSM configuration, init script, cron file, world, JAR, or Google Cloud template is tracked in this repository. Runtime state that the scripts would create (`/opt/msm`, `/etc/msm.conf`, `/etc/init.d/msm`, `/etc/cron.d/msm`, `/opt/build_tools`, `/dev/shm/msm`, `.vagrant/`) is intentionally untracked.

## Execution flows

### `Vagrantfile`

1. Select box `ubuntu/focal64` (Ubuntu 20.04).
2. Forward guest TCP/25565 to host TCP/25565 with no `host_ip` restriction, so Vagrant may bind the forwarded port on all host interfaces.
3. Allocate 2048 MiB RAM to VirtualBox. CPU count is left at the provider default. No extra disk is attached.
4. Provision as root with `DEBIAN_FRONTEND=noninteractive`:
   - `apt-get update` and `apt-get -y upgrade`
   - set a personal global Git identity
   - install `openjdk-17-jre-headless`, `screen`, `rsync`, `zip`, and `jq`
   - download MSM config, init script, and cron file from `git.io` short URLs
   - create user `minecraft` with home `/opt/msm` and login shell `/bin/bash`
   - create world RAM path `/dev/shm/msm`
   - enable MSM as a SysV init service and symlink `/usr/local/bin/msm`
   - run `msm update`, install cron, reload cron, then `msm update --noinput`
   - download `BuildTools.jar` from Spigot Jenkins `lastSuccessfulBuild` into `/opt/build_tools`
5. Provisioning stops after the download. It does not run BuildTools, create an MSM server, accept the EULA, or start Minecraft.

### `01-create-server.sh`

1. Set `gcloud` project to `autismupminecraft`.
2. Create reserved address `au-minecraft-ip` in `us-east4`.
3. Sleep 5 seconds.
4. Create VM `au-minecraft-2023070202` in `us-east4-a`:
   - machine type `e2-standard-4`
   - image family `ubuntu-2204-lts` from `ubuntu-os-cloud`
   - 200 GB `pd-ssd` boot disk
   - Premium network tier
   - the reserved address
5. Add network tags `ssh`, `https`, `webmin`, and `minecraft`.
6. Create four VPC firewall rules on network `default`, each sourced from `0.0.0.0/0`:
   - `allow-tag-ssh`: TCP/22
   - `allow-tag-web-https`: TCP/443
   - `allow-tag-webmin`: TCP/10000
   - `allow-tag-minecraft`: TCP/25565
7. The script does not install software, attach a separate data disk, configure SSH keys beyond the project default, or invoke `02-setup-server.sh`.

### `02-setup-server.sh`

1. Repeat the Vagrant MSM/Java/BuildTools bootstrap without `DEBIAN_FRONTEND=noninteractive`.
2. Then:
   - `sudo adduser auoperator` (interactive password and GECOS prompts)
   - add `auoperator` to groups `sudo` and `minecraft`

The script assumes it is already running with enough privilege to call `apt-get` and `useradd` without `sudo`, then later uses `sudo` for `adduser`/`usermod`. It does not install Webmin, Caddy, nginx, a Minecraft service unit, monitoring, or off-host backups.

### `.gitignore`

Ignores `.vagrant` only. It does not ignore worlds, JARs, `pb_data`, backups, cloud credentials, or other generated runtime data because those artifacts are not produced inside this repository today.

## Assumptions

### Operating system

| Surface | Assumption |
|---|---|
| Vagrant | Ubuntu 20.04 (`ubuntu/focal64`) |
| Google Cloud | Ubuntu 22.04 LTS (`ubuntu-2204-lts`) |
| Init | SysV `update-rc.d` plus `/etc/init.d/msm`; not systemd-native |
| Package manager | `apt-get` with a working default Ubuntu mirror |
| Shell | Bash; `minecraft` is forced to `/bin/bash` |

The local and cloud images already diverge. Replacement work must not inherit this split.

### Java and Minecraft runtime

- Installs `openjdk-17-jre-headless`, a JRE, not a JDK.
- Downloads BuildTools but never compiles Spigot.
- Does not pin a Minecraft or Spigot revision.
- Starts servers later through MSM/`screen` with MSM's default invocation, not containers.
- Default MSM heap is 1024 MB per server, independent of the Vagrant 2048 MB VM or the GCP `e2-standard-4` host.

BuildTools normally needs a JDK, Git, and a pinned revision. The current host is not a complete Spigot build environment.

### Cloud and capacity

| Input | Legacy value |
|---|---|
| Provider | Google Cloud project `autismupminecraft` |
| Region / zone | `us-east4` / `us-east4-a` |
| VM name | `au-minecraft-2023070202` (date-stamped, not reused safely) |
| Machine type | `e2-standard-4` (4 vCPU, 16 GiB RAM) |
| Boot disk | 200 GB `pd-ssd`; worlds live on the boot disk |
| Address | Reserved IP name `au-minecraft-ip` |
| Network | VPC `default`, Premium tier |
| DigitalOcean | Not used |

The target architecture replaces this with a DigitalOcean Droplet, Block Storage Volume, Reserved IP, Spaces backups, and Pulumi from GitHub (M2).

### Network and firewall

| Port | Legacy exposure | Target architecture |
|---|---|---|
| TCP/22 SSH | `0.0.0.0/0` via tag `ssh` | SSH only from approved administrator networks |
| TCP/443 HTTPS | `0.0.0.0/0` via tag `https`; nothing in setup installs a TLS proxy | Management UI on 443, default-deny otherwise |
| TCP/10000 Webmin | `0.0.0.0/0` via tag `webmin`; Webmin is not installed by these scripts | Do not expose |
| TCP/25565 Minecraft | `0.0.0.0/0` via tag `minecraft`; Vagrant also forwards 25565 | Public Minecraft port only |
| TCP/25575 RCON | Not explicitly opened | Must remain private |

No firewall restricts management access by source IP. Vagrant port forwarding may publish Minecraft on the developer workstation.

### Accounts and identity

| Identity | Legacy behavior |
|---|---|
| Git | Hardcoded `Nicholas Hatch` / `nicholas@thehatchcloud.org` as the VM-wide Git identity |
| `minecraft` | Service account, home `/opt/msm`, bash shell, owns MSM paths |
| `auoperator` | Created only by `02-setup-server.sh`; sudoer and member of `minecraft` |
| MSM commands | Run as `minecraft` per downloaded `msm.conf` |
| Staff UI accounts | None; operations require SSH and the `msm` CLI |
| SSH source restriction | None in these scripts |

`adduser auoperator` is interactive and will block or fail in non-interactive automation. Password policy for `auoperator` is not defined in the repository.

### Packages

Explicitly installed: `openjdk-17-jre-headless`, `screen`, `rsync`, `zip`, `jq`.

Used but not installed by the scripts: `git`, `wget`, `curl`, `sudo`, `gcloud` (on the operator workstation), Vagrant/VirtualBox (on the developer workstation).

Not installed, despite firewall or architecture implications: Webmin, a JDK, Docker, Caddy, restic, the DigitalOcean agent, and any Minecraft plugin.

### Filesystem

Downloaded MSM configuration stores:

| Path | Role |
|---|---|
| `/opt/msm` | MSM home, servers, jars, versioning |
| `/opt/msm/servers` | Named server directories |
| `/opt/msm/jars` | JAR groups, including arbitrary download URLs |
| `/opt/msm/archives/worlds` | Local zip world archives |
| `/opt/msm/archives/backups` | Local complete-server zip archives |
| `/opt/msm/archives/logs` | Rolled logs |
| `/dev/shm/msm` | RAM-world copy; volatile tmpfs |
| `/opt/build_tools/BuildTools.jar` | Unpinned BuildTools artifact |
| `/etc/msm.conf` | MSM manager config |
| `/etc/init.d/msm` | MSM control script |
| `/etc/cron.d/msm` | Backup, log-roll, RAM-sync, crash-restart cron |

Worlds are organized as MSM `worldstorage` / `worldstorage_inactive` trees with symlinks into the server directory. That is not the accepted instance-owned layout in ADR 0002 (`/srv/au-minecraft/instances/<name>/...`).

Permissions are `775` on `/opt/msm`, `/dev/shm/msm`, and `/opt/build_tools`, so the `minecraft` group can write the runtime tree. RAM-world mode is enabled in the downloaded `msm.conf`.

## Externally downloaded mutable artifacts

These URLs are fetched at provision time with no checksum, signature, pin, or vendor authenticity check.

| Short or direct URL | Redirect / destination observed 2026-09-06 | Written to | Risk |
|---|---|---|---|
| `https://git.io/6eiCSg` | `https://raw.github.com/marcuswhybrow/minecraft-server-manager/latest/msm.conf` | `/etc/msm.conf` | Mutable config, including `UPDATE_URL` |
| `https://git.io/J1GAxA` | `https://raw.github.com/marcuswhybrow/minecraft-server-manager/latest/init/msm` | `/etc/init.d/msm` | Mutable root-executed init script |
| `https://git.io/pczolg` | `https://raw.github.com/marcuswhybrow/minecraft-server-manager/latest/cron/msm` | `/etc/cron.d/msm` | Mutable cron as user `minecraft` |
| `https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar` | Jenkins last successful BuildTools JAR | `/opt/build_tools/BuildTools.jar` | Floating build, no SHA-256 |
| `msm update` / `msm update --noinput` | MSM then pulls from `UPDATE_URL` in the downloaded conf (`https://raw.githubusercontent.com/msmhq/msm/master` in the current `latest` conf) | MSM installation | Second mutable update channel |

Notes:

- GitHub retired `git.io`. The short URLs still redirected on the inventory date, but they are an abandoned aliasing layer.
- The short URLs point at `marcuswhybrow/minecraft-server-manager` ref `latest`, while the downloaded conf's `UPDATE_URL` points at `msmhq/msm` `master`. First boot can mix two upstreams.
- MSM JAR groups can later download whatever URL an operator stores, including historical Minecraft CDN URLs inside MSM itself.
- Ubuntu `apt-get upgrade` also mutates the guest at provision time.

## Firewall exposure and privileged operations

Privileged operations performed by the scripts:

- Root package upgrade of the entire guest
- Create system user `minecraft` and interactive sudo user `auoperator`
- Write `/etc/msm.conf`, `/etc/init.d/msm`, and `/etc/cron.d/msm`
- `chmod 755` on the MSM init script and register it at boot
- `chmod -R 775` on MSM and BuildTools directories
- Create and chown `/dev/shm/msm`
- `gcloud` project mutation, reserved IP create, VM create, tag assignment, and firewall-rule create
- Open SSH, HTTPS, Webmin, and Minecraft to the entire internet on GCP

Cron installed from the downloaded MSM file, as user `minecraft`:

| Schedule | Command |
|---|---|
| 05:02 daily | `/etc/init.d/msm all worlds backup` |
| 04:55 daily | `/etc/init.d/msm all logroll` |
| Every 30 minutes | `/etc/init.d/msm all worlds todisk` |
| Hourly | `/etc/init.d/msm start` |

Backups are local zip files on the same disk as the live worlds. There is no restic/Spaces copy, volume snapshot, or `save-off`/`save-on` guarantee implemented by these repository scripts themselves; those semantics live inside downloaded MSM.

## Security-sensitive behavior

| ID | Behavior | Severity | Replacement task |
|---|---|---|---|
| S1 | Root init script and config downloaded through `git.io` short URLs with no pin or checksum | Critical | M2-004 host bootstrap; M3-002/M3-003 pinned artifacts; M7-001/M7-003 |
| S2 | `msm update` pulls a second mutable MSM tree from GitHub `master`/`latest` | Critical | Retire MSM (M8-004); manager binary from reviewed GitHub releases (M7-001) |
| S3 | GCP firewall allows SSH TCP/22 from `0.0.0.0/0` | Critical | M2-002 DigitalOcean firewall; M0-007 management-access policy |
| S4 | GCP firewall allows Webmin TCP/10000 from `0.0.0.0/0` even though these scripts never install Webmin | High | Do not recreate. Maintainer confirmed Webmin no longer exists (Q3, 2026-09-07) |
| S5 | HTTPS TCP/443 allowed from `0.0.0.0/0` with no TLS proxy or app installed by setup | High | M7-002 Caddy; M0-007 UI exposure decision |
| S6 | Unpinned `BuildTools.jar` from Jenkins `lastSuccessfulBuild` | High | M0-008 policy; M3-002 pinned BuildTools digest |
| S7 | Interactive sudo user `auoperator` with no password policy, expiry, or MFA | High | M1-004 through M1-008 local staff accounts; M0-007 policy |
| S8 | Hardcoded personal Git identity on every provisioned host | Medium | Remove in replacement bootstrap (M2-004). Do not copy into the Go manager |
| S9 | Group-writable `775` MSM and BuildTools trees | Medium | M2-004/M4 instance directory permissions |
| S10 | RAM worlds enabled in downloaded MSM config (`/dev/shm/msm`) | Medium | M4-007 optional RAM-world, default off, capacity-checked |
| S11 | Local zip backups on the boot disk; no off-host encrypted backup | High | M5-001 through M5-004 restic to Spaces |
| S12 | Minecraft process managed by `screen` as a host user | Medium | M3-004 container runtime boundary; no host shell from the UI |
| S13 | Vagrant forwards 25565 without binding to localhost | Low | Replacement local dev environment (follow-up after M0-002/M3) |
| S14 | `01-create-server.sh` can fail on re-run (duplicate IP, VM, or firewall names) and is not idempotent | Medium | M2 Pulumi state; do not rerun the shell script |
| S15 | Worlds and backups share the 200 GB boot disk | High | M2-003 Volume plus Spaces; ADR 0002 layout |

## Behavior classification

Legend: **preserve** = product capability to keep; **replace** = keep the outcome with a new implementation; **retire** = do not carry forward; **needs maintainer decision** = unknown production dependency.

| Behavior | Classification | Replacement |
|---|---|---|
| Multiple named Minecraft servers | Preserve (via M0-005 parity) | M4 instance catalog |
| Create, delete, rename servers | Replace | M4-002 |
| Start / stop / restart / status, including delayed warning and immediate `now` | Replace | M4-003, M6-002 |
| World list, load, activate, deactivate | Replace with instance-owned storage | ADR 0002; M4-004 through M4-006 |
| RAM-world mode and periodic `todisk` | Replace, default off | M4-007 |
| World-only and complete-server backup | Replace with restic; keep both scopes | M5-001, M5-002 |
| Local zip archives as the only backup | Retire | M5 |
| JAR groups that fetch arbitrary URLs | Replace with pinned BuildTools/Spigot groups | M0-008, M3, M6-006 |
| MSM `config` global defaults and per-server overrides | Replace | M6-006 |
| Player whitelist, bans, ops, kick, give, gamemode, say | Preserve as capabilities | M0-005, M6-003 |
| Console/`cmd` passthrough and log roll | Replace; no host shell | M6-007 |
| Cron backup, log-roll, RAM-sync, crash-restart | Replace with audited jobs/schedules | M4-008, M6-008 |
| MSM Bash/`screen` implementation | Retire | Entire manager stack |
| Vagrant `ubuntu/focal64` MSM workstation | Retire after a replacement dev path exists | Follow-up after M0-002/M3 |
| Google Cloud project, `gcloud` scripts, `e2-standard-4`, `us-east4` | Retire | M2 DigitalOcean |
| Internet-open SSH and Webmin | Retire | M2-002 |
| `git.io` MSM install | Retire | M2-004 |
| Unpinned BuildTools download | Retire | M3-002 |
| `openjdk-17-jre-headless` on the host for Minecraft | Replace | Pinned container JDK (M3) |
| `minecraft` system user owning `/opt/msm` | Replace | Volume layout and container user (M2/M3/M4) |
| `auoperator` sudo SSH operator | Retire | Maintainer confirmed `auoperator` no longer exists (Q4, 2026-09-07). Replacement staff access is browser sessions and capability roles (M1, M0-007) |
| Hardcoded Git user.name/email | Retire | Do not reproduce |
| Webmin TCP/10000 | Retire | Maintainer confirmed Webmin no longer exists (Q3, 2026-09-07). Do not expose TCP/10000 in M2 |
| Existing GCP VM `au-minecraft-2023070202`, reserved IP, worlds, and backups | Retire | Maintainer confirmed the VM, Webmin, `auoperator`, and production worlds no longer exist (Q1–Q5, 2026-09-07). M8-001 creates or imports a new pilot world rather than migrating this host |
| Whether anyone still runs `vagrant up` against this repo | Needs maintainer decision | Q6 |
| Ubuntu 20.04 vs 22.04 split | Retire both as the runtime OS image once M2 pins a host image | M2-004 |

## Maintainer questions

Recorded 2026-09-07 unless noted. Do not delete the in-repo legacy files until M8-004. Remaining open items do not block documenting this inventory.

### Answered

1. **Q1 — Live GCP workload:** Answered 2026-09-07. VM `au-minecraft-2023070202` no longer exists. Treat the Google Cloud create script as historical only.
2. **Q2 — World and backup location:** Answered 2026-09-07. Production worlds no longer exist. M8-001 must create or import a new pilot world; there is no live MSM world tree to migrate from this host.
3. **Q3 — Webmin:** Answered 2026-09-07. Webmin no longer exists. Do not recreate TCP/10000 in DigitalOcean firewall policy.
4. **Q4 — Operator account:** Answered 2026-09-07. `auoperator` no longer exists. Replacement staff access is the manager's local accounts and capabilities (M0-007, M1).
5. **Q5 — MSM server names and JAR groups:** Answered 2026-09-07 by the production-worlds confirmation. No production MSM servers remain to catalog.

### Open

6. **Q6 — Vagrant usage:** Do maintainers still use `vagrant up` from this repository for development or demos?
7. **Q7 — Git identity:** Should `nicholas@thehatchcloud.org` remain associated with any remaining hosts, or was it only a bootstrap convenience?
8. **Q8 — Firewall rule reuse:** Do GCP rules `allow-tag-ssh`, `allow-tag-web-https`, `allow-tag-webmin`, and `allow-tag-minecraft` still exist on leftover project resources even though the named VM is gone?
9. **Q9 — Off-host copies:** Is there any world copy outside the retired GCP VM (download, Drive, another cloud, player-laptop copy) that M8-001 should import, or is the pilot a fresh world?
10. **Q10 — Operational MSM dependency:** Is any external automation (cron elsewhere, staff alias, wiki) still documenting `msm` commands?

## Replacement map

| Retained capability | Later task |
|---|---|
| Document-then-remove legacy files | This inventory; delete only in M8-004 |
| MSM command parity | M0-005, M6-009 |
| Account and management-access policy | M0-007, M1-004 through M1-008 |
| Spigot build policy and pinned BuildTools | M0-008, M3-002, M3-003 |
| Host and firewall | M2-001 through M2-005 |
| Isolated Spigot runtime | M3-004, M3-005 |
| Instances and instance-owned worlds | M4-001 through M4-007 |
| Jobs replacing cron | M4-008, M4-009, M6-008 |
| Encrypted off-host backup and restore | M5-001 through M5-007 |
| Staff web workflows | M6-001 through M6-008 |
| Production deployment | M7-001 through M7-006 |
| World import and legacy retirement | M8-001 creates or imports a new pilot world (no live GCP/MSM world remains); delete in-repo legacy files only in M8-004 |

## Removal criteria for M8-004

Do not remove or rewrite the legacy files until all of the following are true:

1. This inventory is accepted and remaining open questions are answered or explicitly waived.
2. The DigitalOcean path is in production use (M7 complete, M8 pilot running or complete).
3. The pilot world has been created or imported under ADR 0002 layout (M8-001). Maintainers confirmed the legacy GCP VM and its production worlds no longer exist, so M8-001 is not blocked on a GCP world export.
4. Maintainers confirm no person, script, or document still requires `Vagrantfile`, `gcloud` scripts, or host `msm` (Q6, Q10).
5. Any leftover GCP firewall rules, addresses, or project resources are destroyed through a reviewed process or tracked as a separate decommission issue (Q8).
6. M8-004 authorizes retirement.

Until then, treat the files as read-only historical inputs except for deprecation comments that do not change execution.

## Verification

Repository paths referenced by this inventory:

| Path | Present on 2026-09-06 |
|---|---|
| `Vagrantfile` | Yes |
| `01-create-server.sh` | Yes |
| `02-setup-server.sh` | Yes |
| `.gitignore` | Yes |
| `PLAN.md` | Yes |
| `AGENTS.md` | Yes |
| `docs/architecture/minecraft-server-manager-plan.md` | Yes |
| `docs/adr/0001-embed-pocketbase-framework.md` | Yes |
| `docs/adr/0002-instance-owned-world-storage.md` | Yes |

Commands named above (`vagrant`, `gcloud`, `apt-get`, `msm`, and so on) are external tools invoked by the legacy files. They are not tracked in this repository and were not executed against a live environment for this inventory.

No Markdown link checker or `markdownlint` workflow exists in the repository yet (M0-004). Link targets above were checked against `git ls-files`.
