# M0-006: Resolve initial deployment and capacity inputs

## GitHub metadata

- **Milestone:** M0: Repository and decision baseline
- **Labels:** `type:decision`, `needs-human`, `area:infra`, `area:runtime`, `risk:elevated`
- **Dependencies:** None
- **Suggested assignee:** Research agent with human decision owner

## Goal

Produce a decision packet and obtain maintainer approval for the inputs that block the initial Go workspace, DigitalOcean infrastructure, and Spigot runtime.

## Required reading

- `AGENTS.md`
- `PLAN.md`, task M0-006
- `docs/architecture/minecraft-server-manager-plan.md`
- Accepted ADRs

## Decisions required

- Supported Go version.
- Initial Minecraft and Spigot version.
- DigitalOcean region.
- Starting Droplet size and resize trigger.
- Attached Volume starting size.
- Player hostname and management hostname.
- Expected peak concurrent players.
- Number of configured instances and maximum simultaneously running instances.
- Initial per-instance memory reservations and port allocation.
- Initial view distance and simulation distance.
- Initial plugin list and plugin configuration ownership.

## In scope

- Identify viable options and constraints.
- Verify compatibility among Minecraft, Spigot, Java, BuildTools, plugins, and container image.
- Estimate initial host memory reservations without claiming false precision.
- Identify which values are safe configuration and which require an ADR.
- Create `docs/decisions/initial-deployment-inputs.md`.
- Update example configuration only after human approval.

## Out of scope

- Provisioning DigitalOcean resources.
- Purchasing a domain or cloud resources.
- Building Spigot.
- Selecting credentials.
- Making the final decision without a human maintainer.

## Acceptance criteria

- [ ] Every required decision has a recommendation, alternatives, evidence, and consequence.
- [ ] Minecraft, Spigot, Java, BuildTools, plugin, and container compatibility is verified.
- [ ] Capacity assumptions distinguish configured instances from simultaneous instances.
- [ ] Proposed values identify measurement and resize triggers.
- [ ] Hostnames and region are approved or explicitly deferred with a blocking owner.
- [ ] A human maintainer records the final decision.
- [ ] Approved values are reflected in example configuration or a new ADR.
- [ ] M0-002 and M2-001 have no remaining unspecified input from this issue.

## Required validation

- Verify version compatibility using authoritative sources.
- Review memory arithmetic and reserved host overhead.
- Confirm the selected DigitalOcean region supports the required resource types.
- Confirm plugin support for the selected Minecraft and Spigot version.

## Delivery report

List approved values, deferred values, measurement assumptions, human approver, and the tasks unblocked by the decision.

