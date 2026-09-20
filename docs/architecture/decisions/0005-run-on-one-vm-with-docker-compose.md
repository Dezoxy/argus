# 5. Run on one VM with Docker Compose

Date: 2026-09-20

## Status

Accepted

## Context

argus was originally scaffolded for Kubernetes: AKS, Helm charts and Argo CD.
For a messenger with one operator, no traffic yet and no multi-region
requirement, that is a platform to run rather than a product to ship. The
cluster, its upgrades, its ingress controller and its GitOps pipeline all needed
attention that the application was not asking for.

The AKS, Helm and Argo CD scaffolds were removed. They remain in git history if
Kubernetes is ever revisited.

## Decision drivers

- [C-04](../requirements/constraints.md) — one small VM run by one person.
- [C-05](../requirements/constraints.md) — running costs must stay proportionate
  to a project with no revenue.
- [P-02](../principles/architecture-principles.md) — prefer removing a component
  to hardening it.

## Considered options

1. Managed Kubernetes (AKS) with Helm and Argo CD.
2. A platform-as-a-service that runs containers without a cluster.
3. A single VM running the whole stack under Docker Compose.

## Decision

We will run the entire stack — application, datastores, relay and the full
observability stack — as Docker Compose services on one VM, described by
`infra/stack/`, which is deliberately cloud-agnostic.

## Consequences

Positive:

- One machine to understand, patch and back up. The whole runtime fits in one
  `compose.prod.yaml` a person can read.
- The same stack runs unmodified on a second cloud, which is what makes the AWS
  experiment cheap and meaningful.
- Cost stays proportionate to the project.

Negative / accepted trade-offs:

- **No high availability.** The VM is a single point of failure for everything,
  including its own observability stack, which cannot report its own host dying.
- Vertical scaling only; a single managed disk is a shared failure domain for
  every volume.
- Recovery from host loss is a restore, not a failover. The recovery objectives
  and the evidence behind them are in
  [reliability](../reliability/reliability-architecture.md).

## Risks

- [RISK-004](../risks/architecture-risks.md) — the VM is a single point of
  failure.

## Related

- Requirements: [C-04](../requirements/constraints.md),
  [C-05](../requirements/constraints.md)
- Architecture views: AzureDeployment, AwsDeployment
- Other ADRs:
  [6. Expose no inbound port except the call relay](0006-expose-no-inbound-port-except-the-relay.md)
