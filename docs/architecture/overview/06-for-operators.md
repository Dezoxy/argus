# For operators

A reading path for someone running this: how a change reaches the machine,
what watches it, what maintains it, and what to do when the machine is gone.
Four stops.

## How a change reaches the machine

A version tag builds both images, scans them, generates a bill of materials and
signs them. The machine pulls by digest and **verifies the signature before
running anything**. Migrations run before the new version serves traffic.

Two gates, both deliberate: a master switch, and a human approving each
release. There is no SSH — the rollout runs through the cloud control plane.

![Delivery view: how a change reaches the running system, and what gates it](embed:Delivery)

- [Deployment](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/deployment/deployment-architecture.md)

## What watches it

Twelve containers watch six. Metrics, logs, traces, profiles and errors all
land in stores an operator reaches through Grafana, behind an identity gate at
the edge.

**The gap worth knowing before you need it:** all of this runs on the machine
it observes. It reports application faults well and host death not at all — if
the machine stops, so does everything that would tell you.

![Observability view: how a failure becomes a signal someone acts on](embed:Observability)

- [Observability](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/observability/observability-architecture.md)
- [TD-004](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/technical-debt.md): the missing off-host check

## What maintains it

Four scheduled jobs run as native systemd units rather than containers,
reaching the database over the container's local socket because no database
port is published: nightly encrypted backup, attachment expiry, audit pruning
and message retention.

The backup credential **cannot delete**. Reaping is a bucket lifecycle rule,
because a credential that can delete backups is a credential ransomware can
use.

![Maintenance view: the scheduled jobs and the stores they touch](embed:Maintenance)

- [Data](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/data/data-architecture.md): retention, per class

## When the machine is gone

Recovery is a rebuild and a restore, not a failover — that is a decision, not
an oversight. The stack is deliberately cloud-agnostic and the experiment box
on another provider is the proof that rebuilding works.

**The restore has been drilled once, against a synthetic dump — never against
the real backup objects.** Before trusting the runbook,
read what it is honest about: signatures prove a backup is genuine, not that it
is the *latest*, so the restore needs the operator to know the compromise
window.

- [Reliability and recovery](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/reliability/reliability-architecture.md)
- [Disaster recovery runbook](https://github.com/Dezoxy/secmes/blob/main/docs/operations/runbooks/disaster-recovery.md)
- [TD-001](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/technical-debt.md): the drill that would turn the target into a measurement
