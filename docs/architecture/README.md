# Architecture

The front door to how argus is built. argus is a privacy-first, invite-only,
end-to-end-encrypted messenger, installable as a PWA. The server is
**crypto-blind**: it stores and forwards ciphertext and never holds a key that
could read a message.

This page indexes the architecture documents and, once the model lands, the
views and decision records. The binding rules every change must satisfy — the
six security invariants — live in [`AGENTS.md`](../../AGENTS.md), not here.

## Reading paths

**"What is this system and what does it guarantee?"** Start with
[the platform plan](secure_messaging_platform_plan.md), then the invariants in
[`AGENTS.md`](../../AGENTS.md).

**"How does it run in production?"** [deploy.md](deploy.md) — the single EU VM,
Cloudflare Tunnel ingress, Key Vault secrets, and the gated release flow.

**"How is the cryptography put together?"**
[mls-library-selection.md](mls-library-selection.md) for the library choice and
the spike that settled it, then the per-feature notes under
[`docs/threat-models/`](../threat-models/).

**"How do I work on this repository?"**
[security_toolchain.md](security_toolchain.md) for the gates that run on every
commit, and [agent-pipeline.md](agent-pipeline.md) plus
[agent-portability.md](agent-portability.md) for how AI agents are expected to
work here.

## Documents

| Document | What it owns |
| --- | --- |
| [secure_messaging_platform_plan.md](secure_messaging_platform_plan.md) | The architecture as built: passkey-only invite messenger, MLS, single Azure VM via Docker Compose |
| [deploy.md](deploy.md) | Production topology, ingress, secret delivery, CD |
| [security_toolchain.md](security_toolchain.md) | CI gates, local pre-commit, AI-agent guardrails |
| [mls-library-selection.md](mls-library-selection.md) | The `ts-mls` decision and its spike result |
| [agent-pipeline.md](agent-pipeline.md) | How agent work flows through this repo |
| [agent-portability.md](agent-portability.md) | Keeping every agent on one contract |

## Model and views

The Structurizr model lives in [`model/`](model/), with
[`styles-shared.dsl`](model/styles-shared.dsl) copied unchanged from
architecture-base so a colour means the same thing in every workspace built
from it.

The model, the view register and the decision records are **not written yet** —
they land in the branch after this one. This section is the place they go, and
saying so is deliberate: an empty folder that looks populated is worse than an
honest gap.

Local commands, once the model exists:

```bash
make check    # Structurizr validate + inspect
make view     # browse at http://localhost:8080/workspace/1
make export   # SVG, PNG, Mermaid and JSON into generated/
make pdf      # the whole thing as one PDF
```

## Decisions

Architecture Decision Records go in `docs/architecture/decisions/`, one file per
decision, named `NNNN-short-title.md`, using
[the template](templates/adr.md). A changed decision gets a **new** record with
reciprocal supersedes links — decision history is never rewritten.

That folder does not exist yet — git does not track an empty directory, and
`decisions/` may hold nothing but ADRs, so there is no placeholder file to put
in it. It appears with the first record.

No ADRs are recorded yet. The decisions worth capturing are already made and
documented as prose (MLS library choice, passkey-only auth after the Zitadel
decommission, single VM over Kubernetes, Backblaze B2 for attachments); the
next branch turns them into records.

## Keeping this true

`make docs` runs [`scripts/check_docs_consistency.py`](../../scripts/check_docs_consistency.py),
which fails when the documentation contradicts the tree: broken links, an
unindexed document, a malformed ADR, a view register that disagrees with
`views.dsl`, or a cited requirement ID no document defines.

A green run means "nothing provably false" — **not** that the docs are good. It
cannot read prose. Before opening a pull request, follow
[`.claude/skills/docs-sync/SKILL.md`](../../.claude/skills/docs-sync/SKILL.md).
