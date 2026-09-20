# 1. Keep the server crypto-blind

Date: 2026-09-20

## Status

Accepted

## Context

argus is a messenger for people who need their conversations to stay private
from everyone, including whoever operates the service. The operator is a solo
developer on rented infrastructure in the EU; the threat model has to assume the
server, its disks and its backups can be read by someone who should not read
them.

The choice is where message content is readable. A conventional messenger
decrypts on the server so it can search, moderate, generate previews and recover
a user's history. Each of those features needs a key the server holds, and any
key the server holds is a key an attacker, a subpoena or a mistake can reach.

## Decision drivers

- [C-01](../requirements/constraints.md) — the operator must not be able to read
  message content, by design rather than by policy.
- [QA-01](../requirements/quality-attributes.md) — a full compromise of the
  server must not disclose message content.
- [P-01](../principles/architecture-principles.md) — privacy comes from
  cryptography, not from access control.

## Considered options

1. Transport encryption only; content readable on the server.
2. Encryption at rest with a server-held key.
3. End-to-end encryption; the server stores and forwards ciphertext only.

## Decision

We will keep the server crypto-blind. It stores and forwards ciphertext, and
holds no key that can read a message. Encryption and decryption happen only in
the client.

## Consequences

Positive:

- A full host compromise, a stolen disk or a leaked backup discloses metadata,
  not conversations.
- Backups can be shipped to a third-party object store without trusting it.
- Whole classes of feature request are settled in advance, which keeps the
  server small.

Negative / accepted trade-offs:

- No server-side search, moderation, link previews or spam filtering on content.
- No server-assisted history recovery. See
  [4. Store no recoverable secret on the server](0004-store-no-recoverable-secret-on-the-server.md).
- Metadata remains visible to the operator: who talks to whom, when and how
  much. This is a real limit and it is recorded as a risk, not hidden.

## Risks

- [RISK-001](../risks/architecture-risks.md) — metadata exposure to the
  operator.

## Related

- Requirements: [C-01](../requirements/constraints.md),
  [QA-01](../requirements/quality-attributes.md)
- Architecture views: MessageFlow, Containers
- Other ADRs: [2. Use MLS through the ts-mls library](0002-use-mls-through-ts-mls.md)
