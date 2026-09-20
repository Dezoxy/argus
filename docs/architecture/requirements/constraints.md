# Constraints

Fixed conditions the architecture must satisfy. A constraint is not a goal to
optimise: it is something that is already true and cannot be traded away without
a decision that says so explicitly.

| ID | Constraint | Where it comes from | What it rules out |
| --- | --- | --- | --- |
| C-01 | The operator must not be able to read message content, by design rather than by policy. | The product exists for people who do not want to trust the operator. | Server-side search, moderation, link previews, content-aware spam filtering, and any server-held key that opens a message. |
| C-02 | No hand-rolled cryptography. Every primitive comes from a reviewed library, reached through `packages/crypto`. | Solo project; a cryptographic mistake would be invisible until exploited. | Bespoke protocols, primitives used outside the wrapper, `Math.random` anywhere near a key. |
| C-03 | All application code is TypeScript, strict and ESM, and the same crypto code runs in the browser. | One person maintains client, server and shared contracts. | A second server language; a crypto core that cannot run client-side. |
| C-04 | The deployment is one small VM operated by one person. | No team, no on-call rotation. | Anything needing a cluster, a platform team, or attention at 03:00. |
| C-05 | Running cost must stay proportionate to a project with no revenue. | Self-funded. | Managed Kubernetes, multi-region, per-seat SaaS in the critical path. |
| C-06 | Personal data stays in the EU. | GDPR; the stated residency commitment in [`docs/gdpr/`](https://github.com/Dezoxy/secmes/blob/main/docs/gdpr/data-residency.md). | Non-EU regions for anything holding user data or backups. |

## What a constraint costs

C-01 and C-04 pull hardest. C-01 removes whole feature categories before they
are designed, which is the point. C-04 means that every component added is a
component one person patches, so the default answer to "should we add this
service?" is no — recorded as [P-02](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/principles/architecture-principles.md).
