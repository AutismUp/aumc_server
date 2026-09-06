# M0-004: Add the initial continuous-integration workflow

## GitHub metadata

- **Milestone:** M0: Repository and decision baseline
- **Labels:** `type:infrastructure`, `area:ci`, `risk:elevated`, `blocked`
- **Dependencies:** M0-002
- **Suggested assignee:** Go and GitHub Actions implementation agent

## Goal

Create a pull-request CI workflow that proves the Go workspace is formatted, tested, race-safe, statically checked, vulnerability-scanned, secret-scanned, and buildable without granting deployment authority.

## Required reading

- `AGENTS.md`
- `PLAN.md`, task M0-004
- `docs/architecture/minecraft-server-manager-plan.md`, testing and quality gates
- The build commands created by M0-002

## In scope

- Add a GitHub Actions CI workflow for pull requests and the default branch.
- Pin actions to immutable commit SHAs.
- Run formatting verification, unit tests, race tests, `go vet`, static analysis, vulnerability scanning, secret scanning, and binary build.
- Cache only safe Go build and module data.
- Upload useful test or scan results without including secrets.
- Add concurrency cancellation for superseded pull-request runs.
- Document checks that should become branch-protection requirements.

## Out of scope

- DigitalOcean credentials.
- Infrastructure preview or apply.
- Application deployment.
- Spigot BuildTools execution.
- Publishing generated JARs or container images.
- Automatically merging dependency changes.

## Acceptance criteria

- [ ] CI runs on pull requests and pushes to the default branch.
- [ ] Actions are pinned to immutable revisions.
- [ ] Formatting, test, race, vet, static-analysis, vulnerability, secret-scan, and build failures block the workflow.
- [ ] No workflow step requires production credentials.
- [ ] Cache keys cannot expose secrets or accept untrusted executable output.
- [ ] Duplicate runs on superseded commits are cancelled.
- [ ] Required branch-protection check names are documented.
- [ ] A deliberate test failure proves the workflow fails closed before the pull request is completed.

## Required tests

- Validate workflow syntax.
- Exercise the workflow in a pull request.
- Record successful job links.
- Demonstrate at least one intentionally failing check in the branch history or test repository and remove the failure before merge.

## Delivery report

List every action and tool version, permission granted to the workflow token, cache scope, required check name, and any organization-level setting a maintainer must enable.

