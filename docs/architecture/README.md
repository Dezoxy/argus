# Architecture

The front door to how argus is built. argus is a privacy-first, invite-only,
end-to-end-encrypted messenger, installable as a PWA. The server is
**crypto-blind**: it stores and forwards ciphertext and holds no key that could
read a message.

The binding rules every change must satisfy — the six security invariants —
live in [`AGENTS.md`](../../AGENTS.md), not here.

## Status

**Feature-complete; not deployed.** The application is built end to end —
invite-and-passkey registration, 1:1 and group messaging over MLS, encrypted
attachments, multi-device sync, 1:1 audio calls, an admin surface and GDPR
export and deletion. The production infrastructure exists as code.

What is not done is operational: the Azure rollout switch is off, so the
environment described as production is **not running**; the environment that
runs is an experiment holding no real data. Two external gates — an independent
cryptographic review and a penetration test — are open, and the database
restore has never been run against the real backup objects.

[Roadmap](roadmap/roadmap.md) has the order those are worth doing in.

## Reading paths

Each path is a short document in [`overview/`](overview/) that embeds the
diagrams answering its question and links out to whichever register owns each
fact. Pick one rather than reading straight through.

| Path | For someone asking | Stops |
| --- | --- | --- |
| [For stakeholders](overview/03-for-stakeholders.md) | Should this exist, and what does it promise? | 4 |
| [For the CTO](overview/04-for-the-cto.md) | Does the design hold, and what is unproven? | 5 |
| [For engineers](overview/05-for-engineers.md) | What are the pieces, and what must a change satisfy? | 4 |
| [For operators](overview/06-for-operators.md) | How does a change land, what watches it, what if the machine is gone? | 4 |

Start at [What argus is](overview/01-what-argus-is.md) if you want the promise
first, or [Scope](overview/02-scope.md) for what is deliberately excluded.
[Glossary](overview/07-glossary.md) covers the vocabulary.

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

**Every view is embedded in a reading path**, so it appears in the
Documentation tab and the PDF next to the question it answers rather than in a
trailing appendix. An `![alt](embed:Key)` must stay on one line — the PDF
builder matches one embed per line, and a wrapped one silently drops the view
into the appendix while the build still succeeds.

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
| [For stakeholders](overview/03-for-stakeholders.md) | Reading path: what it promises, and what could go wrong |
| [For the CTO](overview/04-for-the-cto.md) | Reading path: exposure, enforcement, what is in the clear, what is unproven |
| [For engineers](overview/05-for-engineers.md) | Reading path: the pieces, the two flows, the rules a change must satisfy |
| [For operators](overview/06-for-operators.md) | Reading path: delivery, observability, maintenance, recovery |
| [Glossary](overview/07-glossary.md) | Terms, in the sense argus uses them |
| [Principles](principles/architecture-principles.md) | `P-NN` — the rules of thumb, and where each does not apply |
| [Constraints](requirements/constraints.md) | `C-NN` — fixed conditions the design had to satisfy |
| [Quality attributes](requirements/quality-attributes.md) | `QA-NN` — measurable claims, each with its evidence or an admission there is none |
| [Assumptions](requirements/assumptions.md) | `A-NN` — what is taken as true, and what breaks if it is not |
| [Security architecture](security/security-architecture.md) | What is defended, from whom, and by what — authn, authz, secrets, exposure, telemetry |
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

## Not documented here

Deliberate omissions, so they read as choices rather than gaps.

- **No component view of the API.** It is one NestJS process with a dozen
  modules; nobody has needed the internal picture enough to maintain one.
- **No network view.** The access-path and deployment views already answer the
  connectivity questions, and a third would duplicate them.
- **No dates on the roadmap.** They are not known, and invented dates are worse
  than none.
- **No runbooks.** Execution procedures live in
  [`docs/operations/`](../operations/); this tree explains the design, and
  links to them rather than restating them.
- **No API or schema reference.** The OpenAPI spec and the migrations are the
  contract; duplicating them here would create a second source of truth that
  goes stale.
- **Per-feature threat models** live in [`docs/threat-models/`](../threat-models/),
  one per feature, written before the code. This tree covers the
  system-level boundaries only.

## Keeping this true

`make docs` runs [`scripts/check_docs_consistency.py`](../../scripts/check_docs_consistency.py),
which fails on a broken link, an unindexed document, a malformed ADR, a view
register disagreeing with `views.dsl`, or a cited requirement ID no document
defines.

A green run means "nothing provably false" — **not** that the docs are good. It
cannot read prose. Before opening a pull request, follow
[`.claude/skills/docs-sync/SKILL.md`](../../.claude/skills/docs-sync/SKILL.md).
