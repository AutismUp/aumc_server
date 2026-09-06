# M0-005: Create the MSM capability parity matrix

## GitHub metadata

- **Milestone:** M0: Repository and decision baseline
- **Labels:** `agent:ready`, `type:research`, `type:documentation`, `area:repository`, `risk:normal`
- **Dependencies:** None
- **Suggested assignee:** Research and product-analysis agent

## Goal

Convert the agreed Minecraft Server Manager capability baseline into stable, testable product capability identifiers that later issues and acceptance tests can reference.

## Required reading

- `AGENTS.md`
- `PLAN.md`, task M0-005
- `docs/architecture/minecraft-server-manager-plan.md`, management utility and MSM capability parity
- Official MSM command documentation referenced by the architecture

## In scope

- Create `docs/product/msm-parity-matrix.md`.
- Assign a stable ID to each approved capability.
- Record the MSM source command or behavior.
- Record the intended web surface and manager API boundary.
- Record required capability permission and default role.
- Record confirmation, reauthentication, and connected-player safeguards.
- Record expected audit event.
- Record acceptance-test intent.
- Mark unsupported, modified, or deferred MSM semantics explicitly.
- Identify gaps or contradictions for maintainer decision.

## Out of scope

- Implementing UI, API, RCON, or runtime behavior.
- Adding capabilities unrelated to the approved MSM baseline.
- Treating arbitrary host commands as an MSM compatibility requirement.
- Resolving architecture conflicts without maintainer approval.

## Acceptance criteria

- [ ] Every MSM capability listed in the architecture has a unique stable ID.
- [ ] Every capability has a web or advanced-interface disposition.
- [ ] Every state-changing capability identifies required authorization and audit behavior.
- [ ] Destructive and immediate actions identify confirmation or reauthentication requirements.
- [ ] Unsupported and intentionally changed semantics include a rationale.
- [ ] Every capability has at least one acceptance-test statement.
- [ ] The matrix identifies unresolved questions separately from approved behavior.
- [ ] A maintainer approves the matrix as the product baseline.

## Required tests

- Cross-check the matrix against the architecture capability table.
- Cross-check command families against the official MSM reference.
- Verify stable IDs are unique.
- Verify every row contains role, audit, and test dispositions.

## Delivery report

Summarize capability counts by area, unsupported or modified behavior, unresolved questions, and the most security-sensitive capabilities.

