# ADR 0001: Embed PocketBase in the Minecraft Manager

- **Status:** Accepted
- **Date:** September 5, 2026
- **Decision owners:** Autism Up Minecraft project maintainers
- **Related document:** `docs/architecture/minecraft-server-manager-plan.pplx.md`
- **Superseded in part by:** [ADR 0002](0002-instance-owned-world-storage.md) replaces the original world-attachment data model with instance-owned worlds.

## Context

The Autism Up Minecraft Server Manager needs a staff-facing web application with local username/password authentication, role-based access, persistent jobs and configuration, audit records, and CRUD-style administration. The project standards favor Go and a simple binary deployment to DigitalOcean. Autism Up does not have an identity provider, so the application must own its user directory and account-recovery process.

Implementing all persistence, authentication, administration, migration, and record-management primitives directly would add substantial security-sensitive code before Minecraft-specific capabilities are delivered. PocketBase provides embedded SQLite, authentication, a dashboard, record APIs, hooks, custom routes, and migrations, and it can be used as a Go framework rather than as an independently deployed backend ([PocketBase documentation](https://pocketbase.io/docs/), [PocketBase framework documentation](https://pocketbase.io/docs/use-as-framework/)). PocketBase is a regular Go package using a pure-Go SQLite implementation, so it can remain part of the project's single compiled manager executable ([PocketBase Go overview](https://pocketbase.io/docs/go-overview/)).

PocketBase does not by itself provide Minecraft orchestration, safe workflow state machines, container control, RCON, BuildTools integration, backups, restore validation, per-instance locking, or the complete capabilities of the Minecraft Server Manager CLI. It is therefore a framework for the control plane, not the control plane product.

## Decision

Embed PocketBase in the `au-minecraft-manager` Go process. Do not deploy PocketBase as a separate network service.

Use PocketBase for:

- SQLite-backed collections and data access.
- Local auth records and username/password credential verification.
- Schema and data migrations embedded in the manager binary.
- Record and request hooks.
- Extension points for custom HTTP routes and root-only CLI commands.
- Internal maintenance tooling, subject to the access restrictions below.

Use custom Go services and routes for:

- Capability-based authorization and the Viewer, Operator, and Administrator roles.
- Revocable browser sessions.
- Minecraft instance, world, player, release, JAR group, schedule, and configuration workflows.
- Docker/Compose control through a narrow privileged boundary.
- RCON commands and console policy.
- BuildTools execution and Spigot release assembly.
- Backup, restore, RAM-world synchronization, and disaster recovery.
- Persisted job state, idempotency, reconciliation, timeouts, and per-instance locks.
- Append-only audit behavior and the staff-facing web interface.

PocketBase's generated record APIs are not the public operational API of the manager. Direct client mutation is denied for operational collections. State-changing staff actions pass through custom routes that enforce capabilities, validate state transitions, coordinate jobs, and record audit events.

## Deployment model

PocketBase is initialized by the manager process and stores its state under `/srv/au-minecraft/manager/pb_data` on the attached DigitalOcean Volume. The web interface is compiled into the same manager binary. PocketBase Go migrations are compiled into that binary and applied during controlled startup; PocketBase documents that Go migrations can be embedded in the final executable and applied automatically with the serve command ([PocketBase Go migrations](https://pocketbase.io/docs/go-migrations/)).

The application remains one versioned systemd service behind Caddy. There is no second PocketBase container, separately exposed port, standalone database server, or independently deployed administration plane.

## Initial data model

| Collection | Type | Purpose |
|---|---|---|
| `users` | Auth | Username/password identity, profile, status, and credential metadata |
| `roles` | Base | Named roles exposed by the staff UI |
| `role_capabilities` | Base | Capability assignments kept separate from page names |
| `app_sessions` | Base | Hashed opaque session identifiers, expiry, rotation, and revocation |
| `instances` | Base | Desired and observed Minecraft instance state |
| `worlds` | Base | Instance-owned world inventory, relative path, activity state, and storage mode |
| `jar_groups` | Base | Approved Spigot build profiles and assignments |
| `releases` | Base | Immutable runtime release metadata and checksums |
| `schedules` | Base | Approved recurring manager jobs |
| `jobs` | Base | Durable orchestration state, progress, and recovery metadata |
| `audit_events` | Base | Actor, action, target, changes, result, and source metadata |
| `settings` | Base | Typed manager settings that are safe to persist |

Collection schemas are defined by reviewed Go migrations. Secrets are not stored in ordinary settings records when root-readable files or systemd credentials are more appropriate.

## Authentication and session model

### Identity and passwords

Configure the `users` auth collection with a required, unique, case-insensitive username identity. PocketBase supports using another unique field such as username instead of email for authentication ([PocketBase authentication](https://pocketbase.io/docs/authentication/)). Email is optional unless email OTP MFA is enabled.

PocketBase password fields use bcrypt with a configurable cost ([PocketBase password field](https://pocketbase.io/jsvm/classes/PasswordField.html)). The production schema will pin and benchmark the cost, initially targeting 12 and refusing a value below 10. This accepts bcrypt as a framework constraint even though OWASP prefers Argon2id for new applications; OWASP's bcrypt guidance requires a work factor of at least 10 when bcrypt is used ([OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)).

The manager additionally enforces:

- A minimum password length of 15 characters when MFA is not enabled.
- Support for at least 64 characters, Unicode, and spaces.
- No composition rules, silent truncation, or periodic forced changes.
- Per-account and per-source rate limiting, generic errors, exponential delays, and security-event logging.
- Password changes after compromise, administrator reset, or recovery.

These rules follow OWASP guidance for password-only accounts ([OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)).

### Browser sessions

Do not send PocketBase bearer tokens to the staff browser or accept them as manager sessions. PocketBase documents that auth tokens are stateless, are not stored in the database, and have no traditional logout endpoint that invalidates an issued token ([PocketBase authentication](https://pocketbase.io/docs/authentication/)). That model does not meet this application's requirement to revoke access immediately after logout, password reset, role change, or account disablement.

After PocketBase verifies credentials, the manager creates an opaque, cryptographically random application session. Only the session identifier is sent in a `Secure`, `HttpOnly`, `SameSite=Strict` cookie; its hash and metadata are stored in `app_sessions`. The manager validates the session, current user status, and current capabilities on every request. Sessions have idle and absolute expiration, rotate after authentication and privilege changes, and can be revoked individually or by user. This follows OWASP guidance to exchange session identifiers through secure cookies and regenerate them after privilege changes ([OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)).

### MFA

PocketBase MFA requires two different enabled authentication methods and documents password plus emailed OTP as an example ([PocketBase authentication](https://pocketbase.io/docs/authentication/)). The first release may enable password plus email OTP for Administrators if Autism Up has reliable SMTP. Authenticator-app TOTP is not assumed to be included and would require a separate implementation and ADR.

### Bootstrap and recovery

There is no default administrator password. Custom root-only CLI commands provide:

- A single-use, short-lived first-administrator setup token.
- A single-use, short-lived break-glass recovery token.

Administrators can issue another user a short-lived reset token and require a password change at the next login. Recovery does not depend solely on email and does not use security questions.

## Administration and API boundary

PocketBase superusers bypass collection rules and can access or modify all data ([PocketBase authentication](https://pocketbase.io/docs/authentication/)). Therefore:

- PocketBase superusers are maintenance identities, not manager staff accounts.
- The PocketBase dashboard is disabled in production when supported, or bound/restricted to localhost for root-only break-glass use.
- The reverse proxy does not publish the dashboard route.
- Staff account administration is implemented in the manager UI through capability-checked custom routes.
- Operational collection rules deny direct client writes and are tested in CI.
- Custom routes never trust a role or capability supplied by the browser.

## Backup and upgrades

PocketBase includes backup and restore APIs that create a full `pb_data` snapshot and can store it locally or in S3-compatible storage ([PocketBase production guidance](https://pocketbase.io/docs/going-to-production/)). The manager creates a PocketBase backup archive before its daily restic backup. It does not make an unsupported raw copy of the live SQLite database.

Before a manager or PocketBase version upgrade:

1. Create and verify a PocketBase backup.
2. Run all migrations against a production-like backup in CI or staging.
3. Start the new manager and execute migration and authorization smoke tests.
4. Retain the prior manager binary and schema-compatible recovery procedure.
5. Block automatic dependency upgrades in production.

## Consequences

### Positive

- The application retains the required Go single-binary deployment model.
- CRUD storage, migrations, auth records, hooks, and basic administration primitives do not need to be written from scratch.
- SQLite avoids a separate database service for this single-host deployment.
- Reviewed Go migrations keep schema changes in the GitHub deployment path.
- Custom routes allow the system to use PocketBase without reducing Minecraft operations to unsafe generic CRUD.

### Negative

- PocketBase becomes a material framework dependency and upgrade risk.
- The application accepts bcrypt rather than the preferred Argon2id password hash.
- PocketBase's default stateless token behavior cannot be used directly for revocable browser sessions.
- The team must maintain a custom application-session layer and test it independently.
- The built-in dashboard is too privileged for ordinary staff use and must be restricted.
- PocketBase is a material embedded dependency, so version pinning and migration testing are mandatory.

### Neutral

- PocketBase does not reduce the amount of Minecraft-domain orchestration required.
- The staff UI still must be purpose-built for non-technical operators.
- Restic remains the primary system and world backup mechanism; PocketBase's backup facility covers manager metadata.

## Alternatives considered

### Custom SQLite and authentication

Implementing `database/sql`, migrations, local accounts, Argon2id password hashing, sessions, CRUD handlers, and administration directly would maximize control and allow Argon2id. It was rejected for the first release because it creates more security-sensitive plumbing and slows delivery of the Minecraft-specific workflows. The custom session layer retained by this decision limits the most important loss of control.

### Standalone PocketBase service

Deploying PocketBase separately would create an additional service, port, lifecycle, health check, version boundary, and credential path. It provides no benefit for the expected single-host deployment and weakens the single-binary standard. It was rejected.

### Existing Minecraft management panel

Crafty Controller, Pterodactyl, Pelican, MCSManager, and LinuxGSM provide useful operational capabilities, but none satisfies the project's Go single-binary standard and exact MSM parity requirement without accepting a different architecture. Crafty remains the fallback if maintaining a custom staff interface proves uneconomic.

## Acceptance criteria

The PocketBase integration is accepted for implementation only when automated tests demonstrate:

- A clean manager binary creates the expected schema through embedded migrations.
- Every supported prior schema migrates to the current schema against a backup copy.
- A user can authenticate with a username without requiring email.
- The configured bcrypt cost meets the project floor and can be upgraded safely.
- Browser requests never receive or authenticate with a PocketBase bearer token.
- Logout, password reset, role change, and account disablement revoke applicable application sessions immediately.
- Direct client mutation of operational collections is denied.
- Custom routes enforce capabilities and write audit events.
- The PocketBase dashboard is unreachable through the public Caddy route.
- PocketBase backup and restore reproduce accounts, sessions, configuration, jobs, and audit records.
- A manager restart reconciles unfinished jobs without bypassing PocketBase-backed state.

## Revisit triggers

Reconsider this decision if:

- PocketBase cannot support a required Go or SQLite upgrade on the supported DigitalOcean platform.
- Security review finds that the embedded superuser or route surface cannot be adequately isolated.
- Migration reliability is insufficient for unattended production startup.
- The project expands to multiple manager nodes requiring a shared database.
- The custom application-session layer becomes more complex than a smaller purpose-built persistence and auth implementation.
