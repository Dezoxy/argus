# 3. Authenticate with passkeys only, behind an invite

Date: 2026-09-20

## Status

Accepted

## Context

Early argus ran a self-hosted Zitadel as an OIDC identity provider. That is one
more stateful service to run, patch, back up and reason about on a single VM,
and it put a password database on the box.

Separately, an open registration form on a private messenger is a liability: it
invites spam accounts and lets anyone enumerate the user base.

Phase 6 removed Zitadel. The API became the identity provider.

## Decision drivers

- [C-04](../requirements/constraints.md) — the deployment is one small VM run by
  one person; every additional stateful service is a real operational cost.
- [QA-03](../requirements/quality-attributes.md) — credential phishing and
  password reuse must not be possible.
- [P-02](../principles/architecture-principles.md) — prefer removing a component
  to hardening it.

## Considered options

1. Keep self-hosted Zitadel as an OIDC provider.
2. Use a hosted identity provider.
3. Make the API the identity provider, with passkeys (WebAuthn) as the only
   credential and an admin-minted invite code as the only way in.

## Decision

We will authenticate with passkeys only. A person joins by redeeming an
invite code an admin minted, and registers a passkey at that moment. There is no
password, no email login, no social login and no self-serve signup. Zitadel is
decommissioned.

## Consequences

Positive:

- Nothing phishable and nothing to reuse: no password exists to steal.
- One fewer stateful service, one fewer database, one fewer thing to patch.
- Invite-only closes user enumeration and spam registration at the door.
- The passkey's PRF extension yields the key that seals the device keystore,
  so the credential and the crypto are the same ceremony.

Negative / accepted trade-offs:

- Growth is gated on an admin minting codes. That is intended here and would be
  wrong for a consumer product.
- Losing every passkey means losing the account. See
  [4. Store no recoverable secret on the server](0004-store-no-recoverable-secret-on-the-server.md).
- A separate break-glass path is now required for the case where no passkey
  works; it is gated at the edge by Cloudflare Access and is deliberately not
  the same path as `/api/admin/*`.

## Risks

- [RISK-003](../risks/architecture-risks.md) — account loss when every
  registered passkey is lost.

## Related

- Requirements: [C-04](../requirements/constraints.md),
  [QA-03](../requirements/quality-attributes.md)
- Architecture views: AccessPaths
- Other ADRs: [4. Store no recoverable secret on the server](0004-store-no-recoverable-secret-on-the-server.md)
