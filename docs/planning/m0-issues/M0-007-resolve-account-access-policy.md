# M0-007: Resolve account, session, MFA, and management-access policy

## GitHub metadata

- **Milestone:** M0: Repository and decision baseline
- **Labels:** `type:decision`, `needs-human`, `area:auth`, `risk:critical`
- **Dependencies:** None
- **Suggested assignee:** Security research agent with human decision owner

## Goal

Define and approve the local-account and network-access policy required to implement authentication, authorization, sessions, recovery, and optional MFA.

## Required reading

- `AGENTS.md`
- `PLAN.md`, task M0-007
- `docs/architecture/minecraft-server-manager-plan.md`, authentication and security sections
- `docs/adr/0001-embed-pocketbase-framework.md`

## Decisions required

- Initial Administrator and Operator account owners.
- Authority to create, disable, and reset accounts.
- Application-session idle lifetime.
- Application-session absolute lifetime.
- Reauthentication window for sensitive actions.
- Login lockout and rate-limit policy.
- Whether the management UI is public HTTPS, source-IP restricted, or placed behind an additional private-access layer.
- Whether reliable SMTP is available.
- Whether password plus email OTP MFA is required for Administrators at launch.
- Break-glass access ownership and recovery evidence.

## In scope

- Prepare realistic options and security trade-offs.
- Recommend defaults consistent with the accepted PocketBase ADR.
- Define normal and break-glass recovery ownership.
- Define audit and alert expectations for authentication events.
- Create `docs/decisions/account-and-access-policy.md`.
- Update architecture or create a new ADR if the approved policy changes an accepted decision.

## Out of scope

- Implementing authentication or sessions.
- Creating real user accounts.
- Handling real passwords, SMTP credentials, or recovery tokens.
- Configuring firewall or DNS.
- Selecting authenticator-app TOTP without a separate architecture decision.

## Acceptance criteria

- [ ] Initial roles and account owners are identified by the maintainer.
- [ ] Session idle, absolute, rotation, and revocation rules are approved.
- [ ] Sensitive reauthentication requirements are approved.
- [ ] Public or restricted management network exposure is decided.
- [ ] SMTP availability and email OTP launch scope are decided.
- [ ] Bootstrap and total-administrator-lockout ownership are documented.
- [ ] Login abuse alerts and audit requirements are documented.
- [ ] A human maintainer records the final decision.
- [ ] M1-004 through M1-008 have no unresolved policy dependency.

## Required validation

- Threat-model credential stuffing, account enumeration, session theft, administrator lockout, SMTP outage, and lost break-glass access.
- Verify approved behavior remains compatible with ADR 0001.
- Review the policy with the person responsible for production access.

## Delivery report

List the approved policy values, risk acceptances, human approver, operational owner, and implementation tasks unblocked.

