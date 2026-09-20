# Architecture

The front door to how argus is built. argus is a privacy-first, invite-only,
end-to-end-encrypted messenger, installable as a PWA. The server is
**crypto-blind**: it stores and forwards ciphertext and holds no key that could
read a message.

The binding rules every change must satisfy — the six security invariants —
live in [`AGENTS.md`](../../AGENTS.md), not here.

## Reading paths

**Stakeholder, non-technical.** [What argus is](overview/01-what-argus-is.md),
then [Scope](overview/02-scope.md), then the SystemContext view, then
[Risks](risks/architecture-risks.md). Skip the rest.

**CTO.** SystemContext and Containers, then AccessPaths and AzureDeployment,
then [Reliability](reliability/reliability-architecture.md) for what recovery
actually looks like, then [Risks](risks/architecture-risks.md) and
[Technical debt](risks/technical-debt.md). The decisions worth arguing with are
[ADR 1](decisions/0001-keep-the-server-crypto-blind.md),
[ADR 4](decisions/0004-store-no-recoverable-secret-on-the-server.md) and
[ADR 5](decisions/0005-run-on-one-vm-with-docker-compose.md).

**Engineer.** Containers, MessageFlow and CallSetup, then
[Data](data/data-architecture.md) and
[Trust boundaries](security/trust-boundaries.md), then the ADRs.

**Operator.** AzureDeployment and AwsDeployment, then Delivery, Observability
and Maintenance, then [Reliability](reliability/reliability-architecture.md)
alongside the runbooks in [`docs/operations/`](../operations/).

## View register

Ten views. Each answers one question for one audience; a view that answers no
question is a diagram, not documentation. `make docs` fails when this table and
`model/views.dsl` disagree.

| Key | Audience | Question it answers | Deliberately omitted | Update trigger |
| --- | --- | --- | --- | --- |
| SystemContext | Everyone | Who uses argus, and what outside systems does it depend on? | Everything internal | Users, scope or an external dependency change |
| Containers | Engineers, CTO | What are the running pieces and how does a message travel between them? | Observability and maintenance, so the message path reads clearly | A container, interface or boundary changes |
| AccessPaths | CTO, engineers | What are the three ways in, and where is each authenticated? | Datastores other than PostgreSQL | Exposure, identity or network policy changes |
| Observability | Operators, engineers | How does a failure become a signal someone acts on? | The message path | Telemetry coverage or alert routing changes |
| Maintenance | Operators | What scheduled work touches the data, and where does it send it? | The request path | A scheduled job, retention rule or credential scope changes |
| Delivery | Operators, engineers | How does a change reach the running system, and what gates it? | Runtime message flow | The release or rollout procedure changes |
| MessageFlow | Everyone | What happens when someone sends a message? | Error paths, retries | Message handling or storage changes |
| CallSetup | Engineers | How does a 1:1 audio call get established? | Call teardown, renegotiation | Signalling or relay behaviour changes |
| AzureDeployment | CTO, operators | Where is production meant to run? **Nothing runs here yet.** | The AWS environment | Hosting, placement or the rollout gate changes |
| AwsDeployment | Operators | Where does the live experiment actually run? | The Azure environment | The experiment's hosting changes |

**Visual verification:** every view was exported and inspected as a rendered
PNG, not only parsed. All use `autoLayout`; there are no maintained
coordinates and no post-export retouching.

**A gap the register should admit:** there is no component-level view of the API.
It is a single NestJS process with a dozen modules, and no one has yet needed
the internal picture badly enough to maintain one.

## Decisions

| ADR | Decision | Status |
| --- | --- | --- |
| 1 | [Keep the server crypto-blind](decisions/0001-keep-the-server-crypto-blind.md) | Accepted |
| 2 | [Use MLS through the ts-mls library](decisions/0002-use-mls-through-ts-mls.md) | Accepted |
| 3 | [Authenticate with passkeys only, behind an invite](decisions/0003-authenticate-with-passkeys-only.md) | Accepted |
| 4 | [Store no recoverable secret on the server](decisions/0004-store-no-recoverable-secret-on-the-server.md) | Accepted |
| 5 | [Run on one VM with Docker Compose](decisions/0005-run-on-one-vm-with-docker-compose.md) | Accepted |
| 6 | [Expose no inbound port except the call relay](decisions/0006-expose-no-inbound-port-except-the-relay.md) | Accepted |
| 7 | [Keep attachments in Backblaze B2](decisions/0007-keep-attachments-in-backblaze-b2.md) | Accepted |

New records go in [`decisions/`](decisions/) as `NNNN-short-title.md`, using
[the template](templates/adr.md). A changed decision gets a **new** record with
reciprocal supersedes links; decision history is never rewritten.

## Documents

The narrative and every register, in reading order. These are the same files
Structurizr imports as its Documentation tab and the PDF prints, reached there
by symlink from [`overview/`](overview/).

| Document | What it owns |
| --- | --- |
| [What argus is](overview/01-what-argus-is.md) | The guarantee, in plain language, and what it does not cover |
| [Scope](overview/02-scope.md) | What is in, what is deliberately out, and why |
| [Glossary](overview/03-glossary.md) | Terms, in the sense argus uses them |
| [Principles](principles/architecture-principles.md) | `P-NN` — the rules of thumb, and where each does not apply |
| [Constraints](requirements/constraints.md) | `C-NN` — fixed conditions the design had to satisfy |
| [Quality attributes](requirements/quality-attributes.md) | `QA-NN` — measurable claims, each with its evidence or an admission there is none |
| [Assumptions](requirements/assumptions.md) | `A-NN` — what is taken as true, and what breaks if it is not |
| [Trust boundaries](security/trust-boundaries.md) | Where control changes hands and what is checked |
| [Data](data/data-architecture.md) | What is stored, how sensitive, where, and for how long |
| [Integration](integration/integration-architecture.md) | Every external system and its failure behaviour |
| [Deployment](deployment/deployment-architecture.md) | The two environments and how a release reaches them |
| [Reliability](reliability/reliability-architecture.md) | What fails together, and how service and data come back |
| [Observability](observability/observability-architecture.md) | How a failure becomes an actionable signal |
| [Risks](risks/architecture-risks.md) | `RISK-NNN` — known ways this hurts, and what remains |
| [Technical debt](risks/technical-debt.md) | `TD-NNN` — deliberate shortcuts and what clearing them costs |
| [Roadmap](roadmap/roadmap.md) | Where it stands and what the risks argue for next |

Longer-standing reference documents sit beside them:
[the platform plan](secure_messaging_platform_plan.md),
[deploy](deploy.md), [security toolchain](security_toolchain.md),
[MLS library selection](mls-library-selection.md),
[agent pipeline](agent-pipeline.md) and
[agent portability](agent-portability.md).

## Working on the model

```bash
make check    # Structurizr validate + inspect; fails on any ERROR
make view     # browse at http://localhost:8080/workspace/1
make export   # SVG, PNG, Mermaid and JSON into generated/
make pdf      # the Documentation tab, the ADRs and every view as one PDF
make docs     # fail when the documentation contradicts the tree
```

The model lives in [`model/`](model/), pulled together by
[`workspace.dsl`](workspace.dsl).
[`styles-shared.dsl`](model/styles-shared.dsl) is copied unchanged from
architecture-base so a colour means the same thing in every workspace built from
it; [`styles.dsl`](model/styles.dsl) only maps argus's five layers onto that
palette.

## Keeping this true

`make docs` runs [`scripts/check_docs_consistency.py`](../../scripts/check_docs_consistency.py),
which fails on a broken link, an unindexed document, a malformed ADR, a view
register disagreeing with `views.dsl`, or a cited requirement ID no document
defines.

A green run means "nothing provably false" — **not** that the docs are good. It
cannot read prose. Before opening a pull request, follow
[`.claude/skills/docs-sync/SKILL.md`](../../.claude/skills/docs-sync/SKILL.md).
