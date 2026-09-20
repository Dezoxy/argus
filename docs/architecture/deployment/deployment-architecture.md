# Deployment

Two environments exist, and the difference between them is the most important
thing on this page.

| | Azure | AWS |
| --- | --- | --- |
| Intended role | Production | Experiment |
| Actually running | **No.** `vars.ENABLE_DEPLOY` is off, so a tagged release does not roll out. | **Yes.** 59 releases to date. |
| Holds real data | Not yet | No, and it is not meant to |
| Region | `germanywestcentral` | `eu-central-1` |
| Host | One `Standard_B2ms` VM, Ubuntu 24.04 | One `t3.medium` EC2 instance |
| Secrets | Key Vault via system-assigned Managed Identity | The same Key Vault, via an Azure Arc-projected identity |
| Deploy channel | `az vm run-command` | AWS SSM |
| What runs there | The whole stack | **The whole stack too** — see below |

**A view labelled simply "production" would be false.** The environment
described as production is not running, and the environment that is running is
labelled an experiment. Both are modelled, and each view says which it is.

## The VM

Everything runs on one machine, as Docker Compose services, plus a few native
systemd units.

- **No service publishes a host port.** CI asserts this, and asserts that coturn
  is the only host-network service.
- **The firewall's only inbound Allow rules are the TURN ports.** There is no
  22, no 80, no 443. HTTP arrives only through the outbound tunnel; deploys
  arrive through the cloud control plane.
- **The maintenance jobs are systemd units, not containers.** They reach
  PostgreSQL over the container's local socket, precisely because no database
  port is published.
- **One managed data disk** holds the PostgreSQL volume and every other volume.
  They share a failure domain, which is stated in the model rather than left for
  someone to discover during an incident.

## How a release reaches it

A semver tag builds both images, scans them with Trivy, generates an SBOM with
syft, and keyless-signs them with cosign. The VM pulls by digest and **verifies
the signature before running anything**. Database migrations run before the new
version serves traffic.

Two gates, both deliberate: `vars.ENABLE_DEPLOY` as a master kill-switch, and
the `prod` GitHub Environment's required reviewer — a human approving each
release.

## What portability bought

`infra/stack/` is cloud-agnostic on purpose, and the AWS box is the proof rather
than the claim: the same stack, the same signed images, a different cloud. That
is also the practical mitigation for
[RISK-004](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/architecture-risks.md) — rebuilding elsewhere is a known
quantity, not a hope.

**"The same stack" is literal, and worth stating because it is easy to assume
otherwise.** `deploy.sh` is the single script both clouds run. `cd-aws.yml`
bundles `infra/stack/observability`, `infra/stack/glitchtip`, `infra/backup`,
`infra/cleanup`, `infra/audit-prune` and `infra/retention`; `deploy.sh` stages
observability unconditionally and installs and arms all four systemd timers.
So the experiment box runs the full twelve-service observability stack and
takes nightly backups, exactly as the production target would. It differs in
what it holds — no real data — not in what it runs.
