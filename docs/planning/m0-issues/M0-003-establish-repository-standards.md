# M0-003: Establish repository contribution and maintenance standards

## GitHub metadata

- **Milestone:** M0: Repository and decision baseline
- **Labels:** `type:documentation`, `area:repository`, `risk:normal`, `blocked`
- **Dependencies:** M0-002
- **Suggested assignee:** Documentation or implementation agent

## Goal

Make the repository understandable and safely maintainable by human contributors and coding agents.

## Required reading

- `AGENTS.md`
- `PLAN.md`, task M0-003
- `docs/planning/github-agent-workflow.md`
- The Go workspace created by M0-002

## In scope

- Create or update `README.md`.
- Create `CONTRIBUTING.md`.
- Create `SECURITY.md` with private reporting guidance.
- Add `CODEOWNERS`.
- Configure dependency-update automation for the dependencies that exist.
- Document supported Go version, local prerequisites, build, test, branch, commit, review, and release conventions.
- Document which files and artifacts must never be committed.
- Link the architecture, ADRs, plan, and agent instructions from the README.

## Out of scope

- Implementing product behavior.
- Configuring production credentials.
- Enabling automatic production dependency upgrades.
- Removing legacy files.
- Creating organization-level GitHub policies.

## Acceptance criteria

- [ ] A new contributor can identify the project purpose and target architecture.
- [ ] A new contributor can build and test the current manager from documented steps.
- [ ] Contribution rules match `AGENTS.md`.
- [ ] Security reports are directed to a private channel.
- [ ] CODEOWNERS covers application, infrastructure, workflows, architecture, and ADR paths.
- [ ] Dependency automation cannot merge or deploy changes without review.
- [ ] Runtime data and secret exclusions are documented and represented in `.gitignore` where appropriate.
- [ ] All repository links resolve.

## Required tests

- Follow the README build and test instructions from a clean checkout.
- Validate CODEOWNERS path patterns.
- Validate Markdown links with available repository tooling.

## Delivery report

Identify any organization settings that maintainers must configure manually, including branch protection, security advisories, and required reviewers.

