# GitHub Agent Workflow

## Sources of truth

- Architecture and constraints: `docs/architecture/` and `docs/adr/`
- Milestone roadmap and dependencies: `PLAN.md`
- Repository-wide agent behavior: `AGENTS.md`
- Current executable work: GitHub issues
- Implementation and validation evidence: pull requests and CI

## Work states

Use these GitHub Project states:

1. Backlog
2. Needs Definition
3. Ready for Agent
4. In Progress
5. Pull Request
6. Human Review
7. Blocked
8. Done

## Milestones

Create one GitHub milestone for each `PLAN.md` milestone:

- M0: Repository and decision baseline
- M1: Embedded manager foundation
- M2: DigitalOcean foundation
- M3: Spigot build and runtime
- M4: Instance and world management
- M5: Backup and recovery
- M6: Staff management experience
- M7: Deployment and production readiness
- M8: Pilot and stabilization

Create detailed issues just in time. Initially create all M0 issues and only the first few M1 issues. Later tasks may change after technical spikes, so do not create a large stale implementation backlog.

## Initial M0 issue drafts

The initial executable issue bodies are stored here until they are created in GitHub:

- [M0-001: Inventory and document the legacy repository](m0-issues/M0-001-inventory-legacy-repository.md)
- [M0-002: Create the initial Go workspace](m0-issues/M0-002-create-go-workspace.md)
- [M0-003: Establish repository contribution and maintenance standards](m0-issues/M0-003-establish-repository-standards.md)
- [M0-004: Add the initial continuous-integration workflow](m0-issues/M0-004-add-continuous-integration.md)
- [M0-005: Create the MSM capability parity matrix](m0-issues/M0-005-create-msm-parity-matrix.md)
- [M0-006: Resolve initial deployment and capacity inputs](m0-issues/M0-006-resolve-initial-deployment-inputs.md)
- [M0-007: Resolve account, session, MFA, and management-access policy](m0-issues/M0-007-resolve-account-access-policy.md)
- [M0-008: Confirm the Spigot BuildTools and artifact-retention policy](m0-issues/M0-008-confirm-spigot-build-policy.md)

When a draft becomes a GitHub issue, preserve its task ID in the title, apply the suggested labels and milestone, replace dependency task IDs with issue links, and add the resulting issue number to the milestone tracker. Keep the draft as durable planning history until the milestone is complete.

## Labels

### Workflow

- `agent:ready`
- `agent:running`
- `agent:review`
- `needs-human`
- `blocked`

### Type

- `type:research`
- `type:decision`
- `type:feature`
- `type:infrastructure`
- `type:test`
- `type:documentation`
- `type:security`
- `type:bug`

### Area

- `area:auth`
- `area:pocketbase`
- `area:runtime`
- `area:worlds`
- `area:backup`
- `area:infra`
- `area:web`
- `area:ci`
- `area:repository`

### Risk

- `risk:normal`
- `risk:elevated`
- `risk:critical`

## Dispatch process

1. The coordinator converts a `PLAN.md` task into a bounded issue.
2. Dependencies, required reading, exclusions, tests, and acceptance criteria are made explicit.
3. A maintainer marks the issue `agent:ready`.
4. One implementation agent creates one branch and pull request for the issue.
5. A separate agent reviews the actual diff and test evidence.
6. A human maintainer approves elevated-risk changes.
7. The coordinator updates the issue, milestone tracker, and `PLAN.md`.

## Human approval gates

Always require human approval for:

- Authentication, authorization, sessions, and account recovery.
- Production infrastructure and firewall changes.
- Credential scope and secret handling.
- Privileged helper and container-control changes.
- Backup deletion, retention, and restore behavior.
- Archive extraction and filesystem ownership.
- Production deployment or rollback.
- Changes to accepted ADRs.

## Initial concurrency

Run no more than two implementation agents concurrently until package, migration, CI, and configuration conventions are stable. Avoid concurrent agents editing the Go module bootstrap, shared router, central configuration, PocketBase migration sequence, or deployment workflow.

The first safe work wave is:

- M0-001: Legacy repository inventory.
- M0-005: MSM parity matrix.

Decision work M0-006 through M0-008 may run in parallel as research, but each requires human approval before implementation depends on it.
