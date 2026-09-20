# 4. Store no recoverable secret on the server

Date: 2026-09-20

## Status

Accepted

## Context

A device keystore sealed by a passkey is unrecoverable if the passkey is gone.
The obvious remedy is a key backup: derive a key from a passphrase with Argon2id
and store the wrapped keystore server-side, so a user who loses their device can
restore it.

argus built that surface and then removed it. The reason is that it reintroduces
exactly what
[1. Keep the server crypto-blind](0001-keep-the-server-crypto-blind.md)
removed. Once the server holds a wrapped keystore, the security of every
conversation rests on a human-chosen passphrase and on an offline attack the
server operator is best placed to run. The guarantee stops being "the server
cannot read your messages" and becomes "the server cannot read your messages
unless your passphrase is weak".

## Decision drivers

- [C-01](../requirements/constraints.md) — the operator must not be able to read
  message content, by design.
- [QA-01](../requirements/quality-attributes.md) — a full compromise of the
  server must not disclose message content.
- [P-01](../principles/architecture-principles.md) — privacy comes from
  cryptography, not from access control.

## Considered options

1. Argon2id-wrapped key backup held server-side.
2. Escrow to a second operator-held key.
3. No server-side recovery at all: a lost passkey is a fresh start.

## Decision

We will store no recoverable secret on the server. The device keystore is sealed
under the WebAuthn PRF unlock key and never leaves the device in a form the
server could open. Losing every registered passkey means losing message history;
the account is re-established from scratch.

Multi-device enrolment, not server escrow, is the answer to device loss: a
second registered device already holds the keys.

## Consequences

Positive:

- The crypto-blind guarantee has no asterisk. There is no passphrase to attack
  offline and nothing to hand over under compulsion.
- The threat model is simpler to state and simpler to review, and there is no
  key-backup surface to get wrong.

Negative / accepted trade-offs:

- Losing every device loses history, permanently. This is severe, and it is the
  price of the guarantee above.
- Users must be told to enrol a second device before they need it. That is a
  product obligation this decision creates.

## Risks

- [RISK-003](../risks/architecture-risks.md) — account loss when every
  registered passkey is lost.

## Related

- Requirements: [C-01](../requirements/constraints.md),
  [QA-01](../requirements/quality-attributes.md)
- Other ADRs:
  [1. Keep the server crypto-blind](0001-keep-the-server-crypto-blind.md),
  [3. Authenticate with passkeys only, behind an invite](0003-authenticate-with-passkeys-only.md)
