# Agent Instructions

## Mission

Build and maintain the Autism Up Minecraft Server Manager described in:

- `PLAN.md`
- `docs/architecture/minecraft-server-manager-plan.md`
- `docs/adr/`

The system is a staff-friendly web implementation of the Minecraft Server Manager capability set. It uses Go, embedded PocketBase, DigitalOcean infrastructure, SpigotMC, instance-owned worlds, and reviewed GitHub deployment workflows.

## Instruction precedence

When instructions conflict, use this order:

1. The assigned GitHub issue and explicit maintainer comments.
2. Accepted ADRs in `docs/adr/`.
3. The architecture document.
4. This file.
5. `PLAN.md`.
6. Existing implementation patterns.

Do not silently resolve a conflict by changing architecture. Stop, explain the conflict, and request a maintainer decision.

## Before coding

1. Read the complete assigned issue.
2. Read the referenced `PLAN.md` task.
3. Read only the architecture sections and ADRs relevant to the issue.
4. Inspect the current repository and recent related changes.
5. Confirm that every dependency listed in the issue is complete.
6. Restate the intended outcome, implementation boundary, and test plan.
7. Stop if requirements are ambiguous, a dependency is missing, or an ADR must change.

## Work boundaries

- Work on one GitHub issue or one explicitly approved related issue group.
- Use a focused branch named `issue-<number>-<short-description>`.
- Keep the pull request independently reviewable.
- Do not expand scope to nearby cleanup unless it is required for the acceptance criteria.
- Record unrelated defects or improvements as follow-up issues.
- Do not begin a later `PLAN.md` milestone merely because its code is convenient to add.
- Do not modify or remove the legacy Vagrant, Google Cloud, or MSM files until M0-001 documents their behavior and M8-004 authorizes retirement.

## Architecture invariants

The following rules require an ADR to change:

- The management application is written in Go and deploys as one versioned binary.
- PocketBase is embedded in that binary, not deployed as a separate network service.
- Browser sessions are opaque, revocable application sessions. PocketBase bearer tokens are not manager browser sessions.
- Operational PocketBase collections cannot be mutated directly by browser clients.
- The PocketBase superuser dashboard is not exposed through the public staff interface.
- Authorization is capability-based and denies access by default.
- Browser-facing code cannot execute arbitrary host commands or use unrestricted Docker access.
- Spigot is built with approved BuildTools inputs on Autism Up infrastructure. Generated Spigot JARs are not committed or published.
- Active and inactive worlds are stored beneath their single owning instance.
- One writable world cannot be active in multiple instances.
- Production data, worlds, PocketBase data, backups, runtime secrets, and generated JARs are never committed.
- Production infrastructure and application deployments run only from reviewed GitHub workflows.
- World rollback is always an explicit administrator operation and never an automatic side effect of runtime rollback.

## Security requirements

- Treat authentication, authorization, sessions, archive extraction, path handling, RCON, container control, backup, restore, and deployment as elevated-risk areas.
- Validate all identifiers, paths, filenames, archive entries, command arguments, and configuration values at trust boundaries.
- Reject absolute paths, parent traversal, unsafe archive links, and paths outside the intended instance.
- Never pass browser input to a shell.
- Never log passwords, reset tokens, session identifiers, PocketBase bearer tokens, API credentials, RCON passwords, or backup credentials.
- Use generic authentication failures and rate-limit abusive requests.
- Require explicit capability checks in every custom state-changing route.
- Record an audit event for every attempted state change, including failures where practical.
- Preserve guaranteed cleanup paths, especially `save-on` after backup errors.
- Do not weaken a security check merely to make a test pass.

## Implementation standards

- Prefer the Go standard library and small, well-maintained dependencies.
- Pin production dependencies and container images.
- Keep package boundaries aligned with the architecture.
- Pass `context.Context` through operations that perform I/O or may block.
- Use explicit timeouts for network, process, RCON, backup, and container operations.
- Make long-running or destructive operations durable jobs rather than open HTTP requests.
- Use idempotency keys and per-instance locks where repeated execution could be harmful.
- Keep configuration typed and validated.
- Return actionable user-facing errors without leaking internal secrets.
- Use migrations for every PocketBase schema change.
- Keep immutable release artifacts separate from mutable instance data.
- Do not add Kubernetes, a message broker, a separate database, or multi-node scheduling without an accepted ADR.

## Testing requirements

Every behavior change must include the appropriate tests:

- Unit tests for business rules, state transitions, path safety, authorization, and failure handling.
- Integration tests for PocketBase, sessions, jobs, restic, RCON, container behavior, and migrations.
- Security tests for capability bypass, path traversal, archive extraction, command injection, CSRF, token replay, and secret leakage.
- Browser tests for staff-visible workflows when UI behavior changes.
- Infrastructure tests for firewall, persistence, immutable references, and deployment policy.
- Recovery tests for interrupted or partially completed destructive operations.

Before requesting review, run all applicable repository checks. At minimum:

```text
go test ./...
go test -race ./...
go vet ./...
```

Use the project-provided commands once the Makefile and CI workflow exist. If a required check cannot run, report exactly why and do not describe the task as fully validated.

## Pull request requirements

Each pull request must:

- Link the issue with `Closes #<number>` when it completes the issue.
- Explain the user or operational outcome.
- List important design choices.
- List files or packages changed.
- List tests and commands actually run.
- Describe security, migration, deployment, and rollback effects.
- Identify assumptions, limitations, and follow-up work.
- Avoid unrelated formatting or refactoring.
- Update documentation and `PLAN.md` status when appropriate.

Do not merge your own work. Elevated-risk changes require an independent agent review and human maintainer approval.

## Completion report

At the end of an implementation session, report:

1. Outcome.
2. Files changed.
3. Tests run and their results.
4. Acceptance criteria satisfied.
5. Security and operational considerations.
6. Assumptions or unresolved questions.
7. Follow-up issues recommended.

