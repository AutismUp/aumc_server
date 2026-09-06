# Autism Up Minecraft Server Manager Development Plan

## Purpose

This file is the execution backlog for building the Autism Up Minecraft Server Manager described in:

- [`docs/architecture/minecraft-server-manager-plan.md`](docs/architecture/minecraft-server-manager-plan.md)
- [`docs/adr/0001-embed-pocketbase-framework.md`](docs/adr/0001-embed-pocketbase-framework.md)
- [`docs/adr/0002-instance-owned-world-storage.md`](docs/adr/0002-instance-owned-world-storage.md)

The target is a staff-friendly web implementation of the Minecraft Server Manager capability set, built as a Go application with embedded PocketBase, deployed from GitHub to DigitalOcean, and operating one or more SpigotMC instances.

This plan intentionally uses dependency-ordered milestones rather than calendar dates. Estimates and dates should be added only after the Phase 0 technical spikes establish the major implementation costs.

## Agent operating rules

Any management or coding agent working from this plan must:

1. Read the architecture document and both ADRs before selecting work.
2. Work on one task or one tightly related task group at a time.
3. Confirm every listed dependency is complete before starting a task.
4. Create a focused branch and pull request for each independently reviewable change.
5. Add or update tests in the same pull request as implementation code.
6. Update task status and add links to the pull request and resulting ADR when work is completed.
7. Never commit credentials, generated Spigot JARs, Minecraft worlds, PocketBase data, backups, or runtime secrets.
8. Never deploy production code directly from a workstation. Production changes flow through reviewed GitHub Actions workflows.
9. Pin third-party versions and verify downloaded artifacts when a checksum is available.
10. Preserve the narrow security boundary: browser requests cannot execute arbitrary host commands, access the Docker socket, or mutate operational PocketBase collections directly.
11. Stop and create an ADR before changing a decision that affects deployment topology, persistence ownership, authentication, authorization, backup semantics, or the Spigot build/distribution model.
12. Keep the repository buildable and its tests passing at the end of every completed task.

## Status legend

- `[ ]` Not started
- `[~]` In progress
- `[x]` Complete
- `[!]` Blocked, with the blocker recorded below the task

## Definition of done

A task is complete only when:

- Its implementation and documentation are committed through a reviewed pull request.
- Unit, integration, policy, or acceptance tests appropriate to the change pass in CI.
- Security-sensitive failure paths are tested.
- User-visible behavior includes actionable error messages.
- Configuration and operational effects are documented.
- No placeholder credentials, unpinned production dependencies, or generated runtime data are committed.
- The corresponding checkbox and evidence links in this file are updated.

## Repository transition

The current repository contains a Vagrant development environment and Google Cloud provisioning scripts from the earlier MSM-based implementation. These files are historical inputs, not the target architecture. They should remain unchanged until the replacement development environment and DigitalOcean deployment path are working.

The existing scripts must not be used for production provisioning because they target Google Cloud, expose broad firewall rules, download mutable scripts through shortened URLs, and install the legacy MSM runtime. Their useful behaviors should be captured in tests or requirements before removal.

## Milestone overview

| Milestone | Outcome | Depends on |
|---|---|---|
| M0: Repository and decision baseline | Reproducible Go workspace, CI, security policy, and resolved Phase 0 decisions | None |
| M1: Embedded manager foundation | Go binary starts PocketBase, applies migrations, serves UI assets, and authenticates safely | M0 |
| M2: DigitalOcean foundation | Reviewed Pulumi workflow provisions the secure persistent host environment | M0 |
| M3: Spigot build and runtime | A pinned Spigot release is built on the host and runs in an isolated test instance | M1, M2 |
| M4: Instance and world management | Multiple instances and instance-owned worlds can be created and managed safely | M3 |
| M5: Backup and recovery | World, instance, manager, and host recovery paths are automated and tested | M4 |
| M6: Staff management experience | Non-technical staff can perform the agreed MSM capability set through the web UI | M4, M5 |
| M7: Production readiness | Security, deployment, monitoring, usability, and disaster-recovery gates pass | M6 |
| M8: Pilot and stabilization | Production pilot completes with measured reliability and documented support procedures | M7 |

## M0: Repository and decision baseline

### Repository foundation

- [ ] **M0-001: Inventory the legacy repository**
  - Dependencies: None
  - Record the behavior provided by `Vagrantfile`, `01-create-server.sh`, and `02-setup-server.sh`.
  - Identify any production data or undocumented workflow that still depends on them.
  - Add a deprecation note without deleting the files.
  - Done when the replacement requirements are traceable and removal criteria are documented.

- [ ] **M0-002: Create the Go workspace**
  - Dependencies: M0-001
  - Create `go.mod`, `cmd/au-minecraft-manager`, and the initial `internal/` package boundaries from the architecture.
  - Add a version command, structured logger, configuration loader, and graceful shutdown.
  - Done when `go test ./...` and a local binary build succeed.

- [ ] **M0-003: Establish repository standards**
  - Dependencies: M0-002
  - Add `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CODEOWNERS`, pull-request template, issue templates, and dependency-update configuration.
  - Document supported Go version, local prerequisites, branch policy, review policy, and release conventions.
  - Done when a new contributor can build and test the empty manager from documented instructions.

- [ ] **M0-004: Add continuous integration**
  - Dependencies: M0-002
  - Run formatting checks, unit tests, race tests, static analysis, vulnerability scanning, secret scanning, and a reproducible binary build.
  - Cache dependencies without caching secrets or generated server artifacts.
  - Done when the protected branch can require all CI checks.

### Product and architecture decisions

- [ ] **M0-005: Create the MSM parity matrix**
  - Dependencies: None
  - Convert every supported MSM command family in the architecture into a stable capability ID.
  - For each capability, record UI surface, API route, role, confirmation requirement, audit event, and acceptance test.
  - Mark intentionally unsupported behavior explicitly.
  - Done when the matrix is approved as the product baseline.

- [ ] **M0-006: Resolve initial deployment inputs**
  - Dependencies: None
  - Decide the first Minecraft and Spigot version, DigitalOcean region, management hostname, player hostname, expected peak players, instance count, memory budget, view distance, and initial plugins.
  - Record decisions in configuration examples or ADRs.
  - Done when no Phase 1 infrastructure or runtime task depends on an unspecified value.

- [ ] **M0-007: Resolve account and access policy**
  - Dependencies: None
  - Identify initial Administrators and Operators, session idle and absolute lifetimes, password-reset authority, management-UI network exposure, SMTP availability, and whether email OTP MFA is in the first release.
  - Done when authentication acceptance tests can be written without policy placeholders.

- [ ] **M0-008: Confirm the Spigot build policy**
  - Dependencies: None
  - Confirm that BuildTools runs in an ephemeral builder on the target host and that generated Spigot JARs remain private on Autism Up infrastructure.
  - Record any legal or organizational review result in an ADR.
  - Done when the build and artifact-retention policy is approved.

## M1: Embedded manager foundation

### PocketBase and persistence

- [ ] **M1-001: Embed PocketBase in the Go process**
  - Dependencies: M0-002
  - Initialize PocketBase from `cmd/au-minecraft-manager`.
  - Store `pb_data` outside the binary and expose no standalone PocketBase service.
  - Add health and readiness routes that do not reveal sensitive state.
  - Done when one binary starts, stops gracefully, and persists a test record.

- [ ] **M1-002: Add embedded schema migrations**
  - Dependencies: M1-001, M0-005
  - Create migrations for `users`, `roles`, `role_capabilities`, `app_sessions`, `instances`, `worlds`, `jar_groups`, `releases`, `schedules`, `jobs`, `audit_events`, and `settings`.
  - Require every world to have one owner instance and a manager-controlled relative path.
  - Do not create `world_attachments`.
  - Done when clean install, upgrade, downgrade policy, and migration-from-backup tests pass.

- [ ] **M1-003: Enforce the PocketBase API boundary**
  - Dependencies: M1-002
  - Deny direct client mutation of operational collections.
  - Ensure the public listener does not expose the PocketBase superuser dashboard.
  - Add tests proving that collection rules and reverse-proxy routes fail closed.
  - Done when only custom manager routes can perform operational mutations.

### Authentication and authorization

- [ ] **M1-004: Implement username/password authentication**
  - Dependencies: M1-002, M0-007
  - Configure a unique case-insensitive username identity.
  - Pin and benchmark the PocketBase bcrypt cost.
  - Enforce password length and safe error behavior.
  - Done when valid, invalid, disabled, locked, and upgraded-password cases pass.

- [ ] **M1-005: Implement revocable application sessions**
  - Dependencies: M1-004
  - Issue opaque server-side sessions after credential verification.
  - Store only hashed identifiers and send secure, HTTP-only, same-site cookies.
  - Implement idle expiry, absolute expiry, rotation, logout, and user-wide revocation.
  - Reject PocketBase bearer tokens as manager sessions.
  - Done when logout, password reset, role change, and account disablement revoke access immediately.

- [ ] **M1-006: Implement capability authorization**
  - Dependencies: M1-002, M0-005
  - Seed Viewer, Operator, and Administrator roles from capability definitions.
  - Authorize each custom route by capability, not by page or role name.
  - Add deny-by-default middleware and table-driven authorization tests.
  - Done when every capability in the parity matrix has an authorization test.

- [ ] **M1-007: Implement bootstrap and recovery commands**
  - Dependencies: M1-004, M1-005
  - Add root-only first-administrator and break-glass recovery commands.
  - Use single-use, short-lived tokens with audit events.
  - Add administrator-issued user reset with forced password change.
  - Done when installation and total-administrator-lockout drills pass without a default password.

- [ ] **M1-008: Add login protection and optional MFA**
  - Dependencies: M1-004, M0-007
  - Add per-account and per-source rate limiting, exponential delays, generic errors, and security alerts.
  - If approved, implement PocketBase password plus email OTP for Administrators.
  - Done when brute-force, enumeration, token replay, and SMTP-failure tests pass.

### Application shell

- [ ] **M1-009: Build the embedded web shell**
  - Dependencies: M1-005, M1-006
  - Select the minimum front-end toolchain needed for accessible forms, tables, progress, and confirmations.
  - Embed compiled assets with Go.
  - Add authenticated navigation for Fleet, Instances, Players, Worlds, Backups, Schedules, Console, Configuration, JAR Groups, and Administration.
  - Done when the binary serves an accessible responsive shell with permission-aware navigation.

- [ ] **M1-010: Implement the audit service**
  - Dependencies: M1-002, M1-005
  - Record actor, capability, action, target, before/after values where appropriate, outcome, source address, release, and timestamp.
  - Prevent staff routes from altering prior events.
  - Done when all state-changing test routes create complete success or failure events.

## M2: DigitalOcean foundation

- [ ] **M2-001: Create the Pulumi Go project**
  - Dependencies: M0-002, M0-006
  - Define project configuration, stack structure, naming, tags, state backend, and secret handling.
  - Done when `pulumi preview` runs in CI without creating resources.

- [ ] **M2-002: Provision network and compute resources**
  - Dependencies: M2-001
  - Define the Droplet, Reserved IP, Cloud Firewall, attached Block Storage Volume, DNS inputs, and service account conventions.
  - Permit only required Minecraft, HTTPS, and restricted administrative traffic.
  - Done when policy tests reject public RCON, globally open SSH, and world data on ephemeral storage.

- [ ] **M2-003: Provision backup and monitoring resources**
  - Dependencies: M2-001
  - Define the private Spaces bucket, retention-related configuration, monitoring agent, alert policies, and notification destinations.
  - Done when backup storage is private and CPU, memory, disk, availability, and backup-freshness alerts can be exercised.

- [ ] **M2-004: Implement minimal host bootstrap**
  - Dependencies: M2-002
  - Install pinned prerequisites, create service accounts, mount `/srv/au-minecraft`, create the approved directory layout, and install service definitions.
  - Keep mutable application deployment outside cloud-init.
  - Done when a replacement Droplet reaches a ready-for-deployment state without manual package installation.

- [ ] **M2-005: Add reviewed infrastructure workflows**
  - Dependencies: M2-001, M0-004
  - Add pull-request preview and protected-branch apply workflows.
  - Scope and document DigitalOcean credentials and emergency revocation.
  - Done when infrastructure cannot be changed by an unreviewed branch.

## M3: Spigot build and runtime

- [ ] **M3-001: Define release and JAR-group schemas**
  - Dependencies: M1-002, M0-006, M0-008
  - Define pinned Minecraft version, BuildTools version and checksum, Java compatibility, container digest, plugins, configuration revision, and release identity.
  - Done when malformed, mutable, or incompatible manifests fail validation.

- [ ] **M3-002: Implement the host-side BuildTools builder**
  - Dependencies: M3-001, M2-004
  - Run BuildTools in an ephemeral restricted builder container.
  - Verify inputs, record the resulting checksum, and keep generated Spigot JARs off GitHub.
  - Done when a clean host can build the selected version reproducibly enough to pass checksum and launch evidence requirements.

- [ ] **M3-003: Implement immutable release assembly**
  - Dependencies: M3-001, M3-002
  - Verify plugin sources and checksums, generate configuration, assemble a versioned release, and make promoted releases read-only.
  - Done when an existing release cannot be changed in place.

- [ ] **M3-004: Implement the narrow runtime control boundary**
  - Dependencies: M2-004, M1-006
  - Define allowlisted start, stop, inspect, and deployment operations without exposing unrestricted root or Docker access to the web process.
  - Done when arbitrary command and arbitrary path attempts are rejected.

- [ ] **M3-005: Launch a disposable Spigot smoke-test instance**
  - Dependencies: M3-003, M3-004
  - Generate a pinned Compose definition using `TYPE=CUSTOM`.
  - Mount the release read-only and a disposable instance `data` directory read-write.
  - Verify health, required plugin loading, RCON isolation, and graceful shutdown.
  - Done when CI or staging can launch and destroy the test instance repeatedly.

- [ ] **M3-006: Implement release promotion and rollback**
  - Dependencies: M3-005
  - Stage a release, back up mutable data, change the instance release pointer atomically, verify health, and restore the prior pointer on failure.
  - Never roll world data backward automatically.
  - Done when interrupted and failed promotions return to the prior healthy runtime.

## M4: Instance and world management

### Instance lifecycle

- [ ] **M4-001: Implement the instance catalog**
  - Dependencies: M1-002, M3-005
  - Track desired state, observed state, port, memory reservation, JAR group, release, path, health, and last reconciliation.
  - Done when two test instances can be represented without resource conflicts.

- [ ] **M4-002: Implement instance create, rename, archive, and delete**
  - Dependencies: M4-001, M1-006, M1-010
  - Enforce safe names and paths, capacity and port checks, stopped-state requirements, backups, typed confirmations, and delayed purge.
  - Done when failure injection cannot leave an orphaned directory or database record.

- [ ] **M4-003: Implement lifecycle and fleet operations**
  - Dependencies: M4-001, M3-004
  - Add start, graceful stop, immediate stop, restart, status, bulk selection, warnings, countdown, cancellation, and partial-failure reporting.
  - Done when concurrent operations honor per-instance locks and host reservations.

### Instance-owned worlds

- [ ] **M4-004: Implement world discovery and ownership**
  - Dependencies: M4-001, M1-002
  - Discover standard and plugin-created worlds under the owning instance.
  - Constrain every stored relative path beneath that instance.
  - Done when path traversal and cross-instance writable mounting are impossible.

- [ ] **M4-005: Implement template cloning and world import**
  - Dependencies: M4-004
  - Validate archives, reject unsafe paths, scan size before extraction, create an independent copy, and record provenance.
  - Done when a template or approved archive produces a healthy instance-owned world without modifying the source.

- [ ] **M4-006: Implement activation, deactivation, move, and export**
  - Dependencies: M4-004, M5-001
  - Require safe instance state, detect name conflicts, create safety backups, and update filesystem plus metadata transactionally.
  - Moving between instances is an explicit export/import operation.
  - Done when interruption recovery leaves one clear owner and no partially active world.

- [ ] **M4-007: Implement optional RAM-world mode**
  - Dependencies: M4-004, M4-003
  - Keep the authoritative disk copy under the owner instance, enforce memory headroom, synchronize periodically, and force synchronization before backup or graceful stop.
  - Done when crash simulations quantify and limit the maximum unsynchronized interval.

### Durable jobs

- [ ] **M4-008: Implement the job engine**
  - Dependencies: M1-002, M1-010
  - Persist jobs with state, progress, actor, idempotency key, timeout, cancellation policy, and per-instance lock.
  - Reconcile interrupted work on manager restart.
  - Done when restart and duplicate-request tests cannot execute destructive work twice.

- [ ] **M4-009: Move runtime and world operations onto jobs**
  - Dependencies: M4-003, M4-005, M4-006, M4-008
  - Expose progress and actionable failures to the UI.
  - Done when no long-running operation relies on an open browser request.

## M5: Backup and recovery

- [ ] **M5-001: Implement consistent world backup**
  - Dependencies: M3-005, M4-008
  - Run `save-off`, `save-all flush`, restic backup, and guaranteed `save-on`.
  - Back up one instance without pausing unrelated instances.
  - Done when timeout and failure injection always re-enable saving.

- [ ] **M5-002: Implement complete-instance backup and export**
  - Dependencies: M5-001, M4-002
  - Use `instances/<name>` as the backup boundary.
  - Include `instance.json`, active and inactive worlds, plugin data, generated configuration, access lists, and required release identity/checksums.
  - Done when a supported archive can reconstruct the instance without hidden database-only path knowledge.

- [ ] **M5-003: Implement PocketBase metadata backup**
  - Dependencies: M1-002, M2-003
  - Use PocketBase's supported backup facility before the daily restic run.
  - Do not copy a live SQLite database directly.
  - Done when accounts, roles, sessions, jobs, settings, and audit metadata restore successfully.

- [ ] **M5-004: Implement retention and repository checks**
  - Dependencies: M5-001, M5-002, M5-003
  - Apply the approved daily, weekly, and monthly retention policy.
  - Record snapshot IDs, verification results, duration, and failures.
  - Done when stale or failed backups generate an actionable alert.

- [ ] **M5-005: Implement world-only restore**
  - Dependencies: M5-001, M4-004
  - Restore into an isolated path, validate in a temporary container, and replace only the selected world directories after approval.
  - Done when unrelated worlds and instance configuration remain unchanged.

- [ ] **M5-006: Implement complete-instance restore**
  - Dependencies: M5-002, M5-003, M3-006
  - Restore the instance directory, verify referenced release artifacts, validate in isolation, and promote atomically.
  - Done when a deleted test instance returns healthy with its prior players, worlds, configuration, and access lists.

- [ ] **M5-007: Automate disaster-recovery exercises**
  - Dependencies: M2-005, M5-006
  - Test replacement Droplet, lost volume, bad plugin, bad release, corrupted world, and locked-administrator scenarios.
  - Capture measured recovery point and recovery time.
  - Done when another maintainer can execute the runbooks without undocumented knowledge.

## M6: Staff management experience

- [ ] **M6-001: Build fleet and instance dashboards**
  - Dependencies: M4-003, M1-009
  - Show state, health, version, players, capacity, backup freshness, active alerts, and recent jobs.
  - Done when stale data is clearly distinguished from healthy live status.

- [ ] **M6-002: Build guided lifecycle workflows**
  - Dependencies: M4-009, M6-001
  - Add individual and bulk start, stop, restart, archive, delete, and rename flows with role-sensitive confirmation.
  - Done when routine operators do not need SSH or command syntax.

- [ ] **M6-003: Build player administration**
  - Dependencies: M3-005, M1-006
  - Implement connected players, whitelist, bans, operators, kick, game mode, give, XP, announcements, time, and weather according to the parity matrix.
  - Done when every action has validation, authorization, RCON handling, and audit coverage.

- [ ] **M6-004: Build world management**
  - Dependencies: M4-009, M5-005
  - Implement instance-owned inventory, template clone, import, export, activate, deactivate, RAM mode, backup history, and restore.
  - Done when the UI never implies that one writable world can be attached to multiple instances.

- [ ] **M6-005: Build backup and restore management**
  - Dependencies: M5-004, M5-006
  - Show policies, schedules, snapshots, retention, verification status, job progress, and restore safeguards.
  - Done when an Administrator can select and validate a restore without shell access.

- [ ] **M6-006: Build configuration and JAR-group management**
  - Dependencies: M3-006, M4-001
  - Provide typed editors, global defaults, per-instance overrides, effective-value preview, restart impact, JAR-group assignment, and staged release deployment.
  - Done when invalid configuration cannot reach production.

- [ ] **M6-007: Build logs and restricted console**
  - Dependencies: M3-005, M1-006
  - Provide sanitized streaming logs and capability-restricted RCON command entry.
  - Never provide a host shell, Docker command, or BuildTools command surface.
  - Done when command allowlists, redaction, output limits, and audit tests pass.

- [ ] **M6-008: Build schedules and notifications**
  - Dependencies: M4-008, M5-004
  - Schedule backups, RAM-world synchronization, log rotation, restarts, announcements, and approved commands.
  - Done when missed, failed, duplicate, and delayed executions are handled predictably.

- [ ] **M6-009: Complete MSM contract tests**
  - Dependencies: M6-002 through M6-008
  - Map every approved capability ID to automated API and browser tests.
  - Done when the parity matrix has no unexplained gaps.

## M7: Deployment and production readiness

- [ ] **M7-001: Build the release pipeline**
  - Dependencies: M0-004, M3-006, M2-005
  - Build and sign or checksum the Go binary, generate release metadata, preserve prior versions, and deploy only reviewed commits.
  - Done when staging deployment and rollback are automated.

- [ ] **M7-002: Add Caddy and production service configuration**
  - Dependencies: M1-009, M2-004
  - Configure HTTPS, security headers, request limits, trusted proxy behavior, service sandboxing, runtime credentials, and restart policy.
  - Done when public exposure is limited to the intended HTTPS and Minecraft endpoints.

- [ ] **M7-003: Complete security review**
  - Dependencies: M6-009, M7-002
  - Review authentication, sessions, CSRF, authorization, archive extraction, path handling, RCON, Docker boundary, secrets, audit integrity, and dependency risk.
  - Done when high-severity findings are resolved and accepted residual risks are documented.

- [ ] **M7-004: Complete accessibility and staff usability testing**
  - Dependencies: M6-009
  - Test routine workflows with at least two non-technical staff members.
  - Review keyboard operation, labels, error recovery, confirmations, progress, and mobile/tablet usability.
  - Done when critical usability failures are resolved.

- [ ] **M7-005: Complete operational runbooks**
  - Dependencies: M5-007, M7-001
  - Document daily checks, alerts, account recovery, deployment rollback, failed backup, restore, storage growth, plugin failure, host loss, and credential rotation.
  - Done when a second maintainer completes the principal drills from the documentation.

- [ ] **M7-006: Production readiness review**
  - Dependencies: M7-001 through M7-005
  - Review capacity, security, recovery evidence, account ownership, support contacts, monitoring, legal decisions, and known limitations.
  - Done when the project owners explicitly approve pilot launch.

## M8: Pilot and stabilization

- [ ] **M8-001: Import or create the pilot world**
  - Dependencies: M7-006
  - Validate the source, import it into the owning instance, establish whitelist and operators, and create a baseline backup.
  - Done when the pilot instance launches from the production workflow and passes gameplay validation.

- [ ] **M8-002: Run a limited production pilot**
  - Dependencies: M8-001
  - Monitor tick health, CPU, memory, disk growth, backup duration, login failures, job failures, and staff support needs.
  - Done when the agreed pilot period completes without unresolved critical incidents.

- [ ] **M8-003: Tune from measured evidence**
  - Dependencies: M8-002
  - Adjust Droplet size, Java heap, view distance, backup frequency, alert thresholds, and UI wording through reviewed changes.
  - Done when capacity and operations remain within approved thresholds.

- [ ] **M8-004: Retire the legacy implementation**
  - Dependencies: M8-003, M0-001
  - Archive or remove the old Vagrant, Google Cloud, and MSM setup only after confirming no operational dependency remains.
  - Preserve relevant history and migration notes.
  - Done when the default repository path documents only supported development and deployment workflows.

- [ ] **M8-005: Conduct the 30-day review**
  - Dependencies: M8-002
  - Review availability, backup and restore evidence, incidents, staff feedback, security events, maintenance cost, and deferred capabilities.
  - Done when follow-up work is accepted into this plan or intentionally declined.

## Cross-cutting test matrix

Every milestone should extend the following test layers:

| Layer | Required coverage |
|---|---|
| Unit | State transitions, path safety, authorization, configuration, retention, RCON parsing, and error mapping |
| Integration | PocketBase migrations, sessions, jobs, restic, container lifecycle, BuildTools, and DigitalOcean API boundaries |
| Security | Authentication abuse, CSRF, capability bypass, archive traversal, command injection, secret leakage, and privileged-helper abuse |
| Browser | Staff login, fleet operations, destructive confirmations, world workflows, backups, restores, and accessibility |
| Infrastructure | Pulumi policies, firewall rules, persistent storage, immutable image references, monitoring, and replacement-host bootstrap |
| Recovery | Interrupted jobs, manager restart, bad release, corrupted world, lost instance, lost volume, and locked administrator |
| Contract | One automated disposition for every approved MSM parity capability |

## Open decisions

Resolve these through the milestone tasks above and link the resulting decision:

- [ ] Initial Minecraft and Spigot version.
- [ ] Initial plugin set and plugin approval policy.
- [ ] DigitalOcean region and starting Droplet size.
- [ ] Expected peak players and maximum simultaneous instances.
- [ ] Player and management hostnames.
- [ ] Management UI network exposure.
- [ ] Initial Administrators and Operators.
- [ ] Session lifetimes and password-reset authority.
- [ ] SMTP availability and first-release email OTP MFA.
- [ ] GitHub branch, environment, and reviewer protections available to the organization.
- [ ] Recovery point, recovery time, and off-provider backup requirements.
- [ ] Organizational approval of the target-host BuildTools policy.

## Immediate execution order

The first agent should take these tasks in order:

1. M0-001: Inventory and document the legacy repository.
2. M0-005: Create the MSM parity matrix.
3. M0-006 through M0-008: Resolve the blocking implementation inputs.
4. M0-002: Create the Go workspace.
5. M0-003 and M0-004: Establish contribution standards and CI.
6. M1-001 through M1-003: Prove embedded PocketBase, migrations, and the API boundary.
7. M1-004 through M1-007: Prove authentication, revocable sessions, authorization, bootstrap, and recovery.

Do not begin the full staff interface until the runtime, authentication, backup, and restore spikes have passed their exit criteria.
