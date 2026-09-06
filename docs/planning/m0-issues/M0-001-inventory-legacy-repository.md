# M0-001: Inventory and document the legacy repository

## GitHub metadata

- **Milestone:** M0: Repository and decision baseline
- **Labels:** `agent:ready`, `type:research`, `type:documentation`, `area:repository`, `risk:normal`
- **Dependencies:** None
- **Suggested assignee:** Research or implementation agent

## Goal

Document the behavior, assumptions, security concerns, and replacement requirements represented by the current Vagrant, Google Cloud, and MSM scripts without changing or deleting them.

## Required reading

- `AGENTS.md`
- `PLAN.md`, task M0-001
- `docs/architecture/minecraft-server-manager-plan.md`
- `Vagrantfile`
- `01-create-server.sh`
- `02-setup-server.sh`
- `.gitignore`

## In scope

- Describe the purpose and execution flow of each legacy file.
- Record operating system, Java, cloud, network, account, package, and filesystem assumptions.
- Identify every externally downloaded mutable artifact or script.
- Record firewall exposure and privileged operations.
- Identify behavior that must be preserved, intentionally replaced, or retired.
- Identify any unknown production dependency that requires maintainer confirmation.
- Add a visible legacy/deprecation notice without changing execution behavior.
- Create `docs/legacy/legacy-implementation-inventory.md`.

## Out of scope

- Deleting or rewriting legacy files.
- Building the Go manager.
- Changing cloud resources.
- Running the scripts against a real environment.
- Migrating production worlds or credentials.

## Acceptance criteria

- [ ] Every tracked legacy file has a documented purpose and dependency list.
- [ ] Google Cloud, Vagrant, MSM, Java, firewall, user-account, and downloaded-script assumptions are identified.
- [ ] Security-sensitive behavior is listed with severity and replacement task.
- [ ] Every behavior is classified as preserve, replace, retire, or needs maintainer decision.
- [ ] A maintainer-question section lists unknown operational dependencies.
- [ ] A deprecation notice points readers to the target architecture and does not break existing scripts.
- [ ] No legacy execution behavior is modified.

## Required tests

- Verify every file and command referenced by the inventory exists in the current repository.
- Run Markdown or link checks available in the repository.
- Verify `git diff` contains documentation changes only.

## Delivery report

Summarize the highest-risk legacy behavior, any information needed from maintainers, and which later tasks replace each retained capability.

