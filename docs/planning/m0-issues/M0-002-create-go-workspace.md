# M0-002: Create the initial Go workspace

## GitHub metadata

- **Milestone:** M0: Repository and decision baseline
- **Labels:** `type:feature`, `area:repository`, `risk:normal`, `blocked`
- **Dependencies:** M0-001 and the Go version portion of M0-006
- **Suggested assignee:** Go implementation agent

## Goal

Create the smallest production-quality Go workspace and manager executable that establishes repository conventions without introducing PocketBase, Minecraft runtime control, or DigitalOcean behavior.

## Required reading

- `AGENTS.md`
- `PLAN.md`, task M0-002
- `docs/architecture/minecraft-server-manager-plan.md`, repository design and implementation boundaries
- M0-001 legacy inventory
- Approved Go version decision from M0-006

## In scope

- Create `go.mod` using the approved module path and Go version.
- Create `cmd/au-minecraft-manager`.
- Add a small internal configuration package with environment and file loading boundaries.
- Add structured logging with secret-safe defaults.
- Add build version, commit, and build-date injection with a `version` command.
- Add signal handling and graceful shutdown.
- Add focused unit tests.
- Add a minimal Makefile or documented commands for format, test, race test, vet, and build.

## Out of scope

- PocketBase initialization or migrations.
- HTTP routes or web assets.
- Authentication and sessions.
- Docker, RCON, BuildTools, restic, Pulumi, or DigitalOcean clients.
- Rewriting or deleting legacy scripts.
- Choosing a large application framework.

## Acceptance criteria

- [ ] `go test ./...` passes.
- [ ] `go test -race ./...` passes.
- [ ] `go vet ./...` passes.
- [ ] The manager builds from a clean checkout.
- [ ] The binary reports version metadata.
- [ ] SIGINT and SIGTERM produce a graceful, bounded shutdown.
- [ ] Configuration errors are actionable and do not reveal secrets.
- [ ] Package layout matches the architecture without empty speculative packages.
- [ ] No production credential or runtime data is committed.

## Required tests

- Unit tests for configuration validation and shutdown behavior.
- Build test with version metadata.
- Race test.
- Invalid-configuration test.

## Delivery report

Report the selected module path, configuration precedence, logger choice, build commands, test commands, and any conventions later agents must follow.

