# Current state and where it is going

## Where it is now

argus is **feature-complete and not yet in production**. That sentence needs
both halves.

The application is built end to end: invite-and-passkey registration, 1:1 and
group messaging over MLS, encrypted attachments, multi-device sync, 1:1 audio
calls, an admin surface, GDPR export and deletion, and a full observability
stack. The production infrastructure exists as code — Terraform, the prod
Compose stack, Key Vault secret delivery, and a build-scan-sign-rollout pipeline
with migrate-before-serve.

What is missing is not features. It is:

- **The Azure production track is gated.** `vars.ENABLE_DEPLOY` is off. Tagged
  releases build, scan and sign, and then stop.
- **The environment that actually runs is the AWS experiment box**, carrying no
  real data, on its own tag namespace and kill-switch. It exists to prove the
  stack is portable and to surface runtime problems before Azure is armed.
- **Two external gates are open**: an independent cryptographic review and a
  penetration test. Neither can be self-served.

## What the architecture would need next

In the order the risks argue for, not in the order of appeal.

| Step | Addresses | Exit criterion |
| --- | --- | --- |
| Exercise a full restore into a scratch database | [TD-001](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/technical-debt.md), [QA-06](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/requirements/quality-attributes.md) | A restored database serves a sample conversation; the recovery time is measured rather than assumed. |
| Add an off-host uptime check | [TD-004](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/technical-debt.md) | The VM stopping produces an alert that does not originate on the VM. |
| Clear the dependency advisories | [RISK-007](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/architecture-risks.md) | The `security` workflow is green on `main`, so the merge rule in `AGENTS.md` is satisfiable. |
| Arm the Azure track | — | A tagged release reaches the VM through the existing two gates, and the AWS box becomes what it claims to be: an experiment. |
| Independent crypto review and pen test | [QA-01](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/requirements/quality-attributes.md) | Both reports received and their findings resolved. |

## What is deliberately not on this list

- **High availability.** One VM is a decision ([ADR 5](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/decisions/0005-run-on-one-vm-with-docker-compose.md)),
  not an oversight. Clustering would be the wrong answer to a service with no
  users yet; a proven restore is the right one.
- **Point-in-time recovery.** Nightly backups are accepted for now
  ([A-05](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/requirements/assumptions.md)). WAL archiving becomes justified when
  argus holds data whose loss would matter to someone other than the operator.
- **Server-side history recovery.** Never. See
  [ADR 4](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/decisions/0004-store-no-recoverable-secret-on-the-server.md).

Dates are not given because they are not known. A roadmap with invented dates is
worse than one without.
