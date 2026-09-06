# M0-008: Confirm the Spigot BuildTools and artifact-retention policy

## GitHub metadata

- **Milestone:** M0: Repository and decision baseline
- **Labels:** `type:decision`, `needs-human`, `area:runtime`, `risk:elevated`
- **Dependencies:** None
- **Suggested assignee:** Technical and policy research agent with human decision owner

## Goal

Confirm the organizational policy for building, storing, deploying, backing up, and retaining Spigot artifacts before the runtime builder is implemented.

## Required reading

- `AGENTS.md`
- `PLAN.md`, task M0-008
- `docs/architecture/minecraft-server-manager-plan.md`, Spigot build and release model
- Official Spigot BuildTools and distribution guidance referenced by the architecture

## Decisions required

- Whether BuildTools runs in an ephemeral builder on the target DigitalOcean host.
- Approved source and verification process for BuildTools.
- Which BuildTools, Minecraft, Spigot, Java, and container versions are recorded.
- Where generated Spigot JARs may be stored.
- Whether generated JARs may enter backup repositories.
- Artifact retention and deletion policy.
- Whether internal host-to-host recovery transfer is permitted.
- Evidence retained for each build.
- Human or organizational owner for policy approval.

## In scope

- Verify current authoritative guidance.
- Compare target-host build, CI build, and package-registry approaches.
- Recommend the lowest-risk approach consistent with reproducible deployment.
- Define artifact paths, permissions, retention, backup scope, and audit evidence.
- Create or update an ADR recording the approved policy.

## Out of scope

- Running BuildTools.
- Uploading or publishing a generated Spigot JAR.
- Giving legal advice.
- Implementing the builder.
- Selecting unreviewed plugins.

## Acceptance criteria

- [ ] Authoritative BuildTools and distribution guidance is linked and summarized.
- [ ] Target-host, CI, and registry approaches are compared.
- [ ] The approved build location and trigger are explicit.
- [ ] Generated-JAR storage, permission, backup, transfer, retention, and deletion rules are explicit.
- [ ] Build evidence and checksum requirements are explicit.
- [ ] The policy states that generated JARs are not committed to Git or attached to public releases.
- [ ] A human maintainer records the final organizational decision.
- [ ] The result is stored in an accepted ADR.
- [ ] M3-001 and M3-002 have no unresolved artifact-policy dependency.

## Required validation

- Recheck current Spigot BuildTools documentation.
- Verify the proposed Java version bounds for the selected Minecraft version.
- Confirm backup and disaster-recovery procedures do not silently violate the approved artifact policy.

## Delivery report

List the approved build path, artifact handling rules, retained evidence, human approver, unresolved legal questions, and tasks unblocked.

