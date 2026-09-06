# ADR 0002: Store Active Worlds Inside Their Owning Instance

- **Status:** Accepted
- **Date:** September 6, 2026
- **Decision owners:** Autism Up Minecraft project maintainers
- **Related document:** `docs/architecture/minecraft-server-manager-plan.pplx.md`
- **Supersedes:** The shared-world and `world_attachments` portions of ADR 0001

## Context

The initial architecture placed mutable worlds in a global world store and used records to attach selected worlds to Minecraft instances. That model made worlds independently portable and followed Minecraft Server Manager concepts such as loading, activating, deactivating, and backing up individual worlds.

For Autism Up, the expected operational model is simpler: an active world normally belongs to one named server instance. A global writable world store would require attachment records, mount or link management, and additional recovery logic. It would also make the filesystem less obvious to an administrator who needs to inspect, copy, archive, or restore a complete instance.

## Decision

Every active or inactive world has exactly one owning Minecraft instance, and its persistent files are stored beneath that instance's directory.

The standard layout is:

```text
/srv/au-minecraft/
├── instances/
│   └── <instance-name>/
│       ├── instance.json
│       ├── current -> ../../releases/<release>
│       ├── data/
│       │   ├── world/
│       │   ├── world_nether/
│       │   ├── world_the_end/
│       │   ├── plugins/
│       │   ├── logs/
│       │   ├── whitelist.json
│       │   └── ops.json
│       └── inactive-worlds/
├── world-templates/
└── archives/
    ├── instances/
    └── worlds/
```

The complete `data` directory is mounted as the instance container's `/data` directory. Standard Spigot worlds and plugin-created worlds therefore remain in the normal server data tree. Inactive worlds remain under the same owning instance but outside the active `/data` paths.

Reusable starter worlds are immutable templates, not active worlds, and remain under `world-templates`. Exported or retired data remains under `archives`. Immutable releases and JAR groups remain global because they are reviewed artifacts intentionally shared across instances.

## Ownership and movement rules

- A world record contains `instance_id`, activity state, storage mode, and a relative path beneath the owning instance.
- The manager rejects absolute paths, parent-directory traversal, and paths outside the owning instance.
- One writable world cannot be mounted into two instances.
- Loading a template clones it into the destination instance, creating a new owned world.
- Importing an archive copies it into the destination instance after validation.
- Moving a world between instances is an explicit stopped-server export/import operation.
- Cloning creates an independent copy with a new identity and backup history.
- Deactivation moves the world into the owning instance's `inactive-worlds` area after a safety backup.
- Reactivation moves it back into the appropriate active data path after conflict and compatibility checks.
- RAM-world mode uses a temporary runtime copy, but the authoritative disk copy remains beneath the owning instance.

## Backup and restore

The instance directory is the natural complete-backup boundary. A complete-instance backup includes `instance.json`, active and inactive worlds, plugin data, generated configuration, access lists, and recovery-relevant logs. The release identifier and checksums in `instance.json` identify the immutable artifacts required to reconstruct the runtime.

World-only backups remain supported by selecting the relevant world directories inside the instance. A world-only restore changes only those selected directories. A complete-instance restore reconstructs the complete instance directory and reconnects it to the referenced immutable release.

A manual archive must be created only after the server is stopped or safely quiesced. For an online archive, the manager sends `save-off`, sends `save-all flush`, creates the archive, and then sends `save-on` in a guaranteed cleanup path. Directly zipping a live instance directory without that coordination is not a supported backup because world and player files may change during the copy.

## Data-model effect

The `world_attachments` collection is removed. The `worlds` collection contains a required owner reference to `instances` and a manager-controlled relative path. The manager UI may still present a fleet-wide world inventory by querying all owned worlds, but the global view does not imply shared storage or transferable attachment.

Deleting an instance requires an up-to-date complete backup and an explicit decision to archive or delete every owned world. An instance cannot be deleted while owned world records remain unresolved.

## Consequences

### Positive

- All mutable data for one server is organized beneath one obvious directory.
- Complete-instance backup, archive, inspection, and recovery have a natural boundary.
- The manager no longer needs writable cross-instance world attachments.
- Filesystem state remains understandable during manual disaster recovery.
- Accidental simultaneous use of one writable world by multiple servers is prevented by construction.
- PocketBase stores ownership metadata without becoming the only way to discover where a world's files belong.

### Negative

- Moving a world between instances requires an explicit copy or move operation.
- Shared use of one persistent world by multiple instances is not supported.
- Large world clones consume additional storage.
- Immutable release artifacts remain outside the instance directory, so a raw archive relies on `instance.json` and the release repository for full reconstruction.

### Neutral

- The manager still supports world-only backup, restore, activation, deactivation, and RAM mode.
- A fleet-wide Worlds page remains useful even though the underlying storage is instance-owned.
- Reusable templates remain global because they are copied rather than attached.

## Alternatives considered

### Global shared world store

The original design stored worlds independently and attached them to instances. It offered maximum portability but required attachment metadata, filesystem indirection, and more complicated lifecycle and recovery handling. It was rejected because the expected one-owner operational model does not justify that complexity.

### Duplicate worlds under both global and instance paths

Maintaining a global canonical copy and a separate instance copy would make ownership unclear and require continuous synchronization. It was rejected because it creates two possible sources of truth.

### Store immutable releases inside every instance

This would make each directory entirely standalone but duplicate Spigot JARs and plugin releases, complicate security updates, and weaken atomic release promotion. It was rejected. Complete exports instead include the release identity and checksums needed for reconstruction.

## Acceptance criteria

The implementation must demonstrate that:

- A newly created instance stores all active world files beneath its own directory.
- A world path cannot escape its owning instance.
- No writable world can be active in two instances.
- Template cloning produces an independent instance-owned copy.
- World import, export, move, activation, and deactivation require the appropriate instance state and safety backup.
- A complete-instance backup and restore operate on the instance directory as one unit.
- A world-only restore does not alter unrelated worlds or instance configuration.
- RAM-world synchronization writes back only to the owning instance.
- Instance deletion cannot orphan world records or files.
- An exported instance identifies every external immutable release artifact needed to reconstruct it.
