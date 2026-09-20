## For the CTO

A reading path for someone judging whether the design holds: what is exposed,
how the promise is enforced rather than asserted, what data exists in the
clear, where it runs, and what fails together. Five stops, each with the
decision behind it.

### What is exposed, and where each way in is authenticated

There are three ways in and they are gated differently. Members and
administrators arrive through Cloudflare over an outbound-only tunnel — **no
HTTP port is open on the machine at all**. The break-glass login, used when no
passkey works, sits behind a separate identity gate at the edge.

The asymmetry worth understanding: `/api/admin/*` is **not** behind that edge
gate, while break-glass is. An administrator is an ordinary authenticated
member whose role is checked in the application against the database; break-glass
exists precisely because normal authentication has failed, so it cannot rely on
it.

![Access paths view: the three ways in and where each is authenticated](embed:AccessPaths)

- [Security architecture](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/security/security-architecture.md): what is defended, from whom, and by what
- [Trust boundaries](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/security/trust-boundaries.md): every crossing and what is checked at it
- [ADR 6: expose no inbound port except the call relay](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/decisions/0006-expose-no-inbound-port-except-the-relay.md)
- [ADR 3: authenticate with passkeys only](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/decisions/0003-authenticate-with-passkeys-only.md)

### How the promise is enforced rather than asserted

The server being unable to read messages is a property of where the keys live,
not a policy someone follows. Every cryptographic operation happens on the
member's device; the server receives an opaque envelope.

The decision that keeps it honest is the one *not* taken: there is no
server-side key recovery, because a recoverable backup would reduce the
guarantee to "unless your passphrase is weak" — and the operator is best placed
to run that attack.

![Container view: the running pieces and how a message travels between them](embed:Containers)

- [ADR 1: keep the server crypto-blind](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/decisions/0001-keep-the-server-crypto-blind.md)
- [ADR 4: store no recoverable secret on the server](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/decisions/0004-store-no-recoverable-secret-on-the-server.md)
- [QA-01](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/requirements/quality-attributes.md): a full host compromise must not disclose message content

### What is in the clear, and what is not

The honest split. Message bodies are opaque to the server. **Everything needed
to route them is not**: display names, argus-ids, group membership, timings,
sizes. Calling the database "encrypted" would be false.

Tenant isolation is enforced in PostgreSQL — FORCE row-level security on every
tenant-scoped table, with the application connecting as a role that cannot
bypass it and the tenant set per transaction from the verified session, never
from client input.

- [Data](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/data/data-architecture.md): every store, its classification, residency and retention
- [RISK-001](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/architecture-risks.md): metadata exposure, accepted and unmitigated in kind

### Where it runs, and what fails together

One virtual machine in an EU region runs everything — application, database,
relay, and the twelve containers that watch them. They share a host and a
disk, so they share a failure domain, including the monitoring that would
report the failure.

**The environment described as production is not running.** Its Terraform,
compose stack, secret delivery and signed-image rollout all exist; the rollout
switch is off. The environment that runs is an experiment carrying no real
data — which is why both are modelled rather than one being labelled
"production".

![Azure deployment view: where production is meant to run, with the rollout gated](embed:AzureDeployment)

![AWS deployment view: the experiment box that actually runs today](embed:AwsDeployment)

- [Deployment](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/deployment/deployment-architecture.md): the two environments and how a release reaches them
- [ADR 5: run on one VM with Docker Compose](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/decisions/0005-run-on-one-vm-with-docker-compose.md)
- [RISK-004](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/architecture-risks.md): the VM is a single point of failure

### What is unproven

Backups are encrypted to a key the machine does not hold, written to
write-once storage that nobody — not the operator, not the provider — can
delete or shorten, and signed with a key the storage credential lacks.

**And the restore has never been run against the real backup objects.** The
procedure was drilled once, on 2026-06-14, against a synthetic dump on a
scratch cluster — it verified data, schema, every RLS policy and per-role
grant, and it found a real gap that has since been fixed. That is genuine
evidence, and it is not the same thing as restoring the actual production
backups in the armed environment, which has never happened. The recovery time
has never been measured at all. That gap is why the recovery objective is the
weakest claim in the whole set.

- [Reliability and recovery](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/reliability/reliability-architecture.md): what fails, what notices, what comes back
- [TD-001](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/technical-debt.md): the restore drill, and what clearing it costs
