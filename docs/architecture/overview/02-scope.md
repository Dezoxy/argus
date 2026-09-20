## Scope

### In scope

- One-to-one and group messaging, end-to-end encrypted, across multiple devices
  per person.
- Encrypted attachments, transferred directly between the browser and object
  storage so the server never handles the bytes.
- One-to-one audio calls, always relayed, so neither party learns the other's
  network address.
- Invite-only registration and passkey-only authentication.
- A metadata-only administrative surface, and an audited break-glass path for
  the case where no passkey works.
- Data-subject export and deletion.
- Running the whole thing on a single EU virtual machine, with the backups,
  monitoring and release pipeline that implies.

### Out of scope, deliberately

| Not built | Why |
| --- | --- |
| Server-side search, moderation, link previews, content spam filtering | Each needs a key the server must not hold. |
| Account or history recovery by the operator | Same reason. A lost passkey is a fresh start. |
| Federation or interoperability with other messengers | Every bridge is a place plaintext could surface. |
| Group audio or video calling | 1:1 audio shipped; video is planned, group calling is not. |
| Native mobile applications | The PWA installs. A native pivot is planned only, and gated on a cryptography spike. |
| Public self-service signup | Invite-only is a design choice, not a launch limitation. |
| Payments and billing | Built, then removed. The inert remains are tracked as debt. |
| High availability, multi-region | One VM is a deliberate decision for a service with no users yet. |

### Boundaries

argus ends at the member's device. Everything inside that device — the
plaintext, the message keys, the sealed keystore — is inside the boundary;
everything the server sees is outside it.

Externally, argus depends on Cloudflare for all reachability, Backblaze B2 for
attachment and backup storage, Azure Key Vault for secrets, and browser push
services for notifications. Each is listed in **Integration** with what happens
when it is unavailable.

### Not covered here

Product roadmap detail, per-feature threat models and operational runbooks live
elsewhere in the repository. This section covers architecture: the structure,
the guarantees and the trade-offs behind them.
