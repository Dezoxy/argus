# Security architecture

How the system is defended, in one place. [Trust boundaries](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/security/trust-boundaries.md)
covers where control changes hands; this covers the controls themselves.

The six invariants a change must not violate live in
[`AGENTS.md`](https://github.com/Dezoxy/secmes/blob/main/AGENTS.md). They are
binding rules, not aspirations, and a change that breaks one is wrong even if
it works.

## What is being defended, and from whom

| Asset | Protected from | By |
| --- | --- | --- |
| Message content | Everyone including the operator | End-to-end encryption; the server holds no key that opens it |
| Message metadata | Everyone except the operator | Access control, audit, argus-id-only discovery. **Weaker by nature** — see [RISK-001](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/architecture-risks.md) |
| Device key material | Everyone including the operator | Sealed in the device keystore under the WebAuthn-PRF key; never leaves the device in openable form |
| Attachments | The storage provider, anyone who obtains the bucket | Encrypted in the browser before upload; the API only mints presigned URLs |
| Backups | The storage provider, ransomware, a compromised host | `age` encryption to a key not on the host, Object Lock, a credential without delete, Ed25519 signatures |
| Runtime secrets | Anything reading the filesystem or process table | Key Vault via Managed Identity, delivered as tmpfs credential files, never environment variables |

## Authentication

**Members and administrators**: passkeys only. No password exists, so none can
be phished, reused or leaked. Joining requires an invite code an admin minted.
The passkey's PRF extension also yields the key that seals the device keystore,
so signing in and unlocking the keys are one ceremony rather than two secrets.

**Break-glass**: a username and password login that exists for when no passkey
works. It is gated at the edge by an independent identity provider, because a
recovery path cannot depend on the mechanism that failed. The edge returns 404
rather than 403 when the gate is not satisfied, so the path does not confirm it
exists.

**Service-to-service**: none. There is one application process; the maintenance
jobs reach the database over the container's local socket, not over a
credentialed network path.

## Authorization

Authorization is checked at two layers, deliberately.

**In the application**: every route carries an explicit posture — `@Public` or
guarded — and a controller spec pins it, so a route silently losing its guard
fails a test rather than shipping. The admin guard re-reads the role from the
database under RLS and checks session revocation rather than trusting a claim
in a token.

**In the database**: the crossing itself, and what is enforced at it, belongs
to [trust boundaries](trust-boundaries.md). What matters here is the *shape* of
the control: it is enforced by the database rather than by application code, so
a missed `WHERE` clause cannot leak across tenants — the database refuses
rather than the query being careful.

## Secrets

No secret is committed, and none reaches an environment variable. The delivery
path — Key Vault to Managed Identity to tmpfs credential file — is a boundary
crossing and is described in [trust boundaries](trust-boundaries.md). The
control worth stating here is the choice behind it: the VM authenticates with
an identity rather than a stored credential, so there is no bootstrap secret to
leak.

What necessarily lives on the host: the session signing key, the TURN shared
secret and the backup signing key. A full host-root compromise reaches those.
That is a strictly smaller exposure than an off-host key would be, and it is
recorded as [TD-005](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/technical-debt.md) rather than
described as solved.

A non-secret value may use environment configuration — an S3 access-key **id**
rides in every presigned URL and is not a secret. The matching secret may not.

## Exposure

The machine answers on the call-relay ports and nothing else. There is no 22,
no 80, no 443. HTTP arrives only through an outbound tunnel the machine itself
opens, and deploys arrive through the cloud control plane rather than a shell.

CI asserts the shape this depends on: no Compose service publishes a host port,
and exactly one service uses host networking. Those are executable assertions,
not conventions.

## Sensitive data in telemetry

No signal may carry message content. Logs carry identifiers and metadata;
traces carry spans, not payloads; error reports carry stack traces. Presigned
URLs, `Authorization` headers, passphrases and keys are never logged.

This is the invariant most likely to be broken by an ordinary, well-meant
change — a debug line added during an incident — which is why it is enforced by
review and by the pre-commit scanners rather than left to memory.

## What this does not cover

- **Per-feature threat models** live in [`docs/threat-models/`](https://github.com/Dezoxy/secmes/blob/main/docs/threat-models/),
  one per feature, written before the code.
- **The toolchain** that enforces the above — CI gates, pre-commit hooks,
  scanners — is [`security_toolchain.md`](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/security_toolchain.md).
- **Independent validation.** No external cryptographic review and no
  penetration test has been performed. Both are open gates, and until they
  close, every claim here is self-assessed.
