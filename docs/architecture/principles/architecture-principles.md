# Architecture principles

Rules of thumb this system is actually built on. Each says what it implies in
practice and where it does not apply — a principle with no stated exception is
usually a slogan.

| ID | Principle | In practice | Exception |
| --- | --- | --- | --- |
| P-01 | Privacy comes from cryptography, not from access control. | If a guarantee depends on the server behaving well, it is not a guarantee. Content is encrypted before it reaches the server. | Metadata. It genuinely is protected by access control, and [RISK-001](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/architecture-risks.md) records that this is weaker. |
| P-02 | Prefer removing a component to hardening it. | Zitadel was removed rather than secured; Kubernetes was dropped rather than tuned. A component not running needs no patching. | Observability. It adds components deliberately, because an unobservable single VM fails silently. |
| P-03 | The server holds no secret it does not need. | Secrets arrive from Key Vault as tmpfs credential files, never environment variables; the backup key can write but not delete; no recoverable user secret is stored at all. | The session signing key and the TURN shared secret must exist on the box for the service to function. |
| P-04 | Make the safe path the only path. | Relay-only transport is forced server-side, not requested politely by the client. The tenant context is set per transaction rather than trusted from input. CI asserts no host port is published. | None so far. Where a safe default cannot be enforced mechanically, that is recorded as debt. |
| P-05 | An architecture claim that cannot be checked will drift. | Counted claims get a gate: `make docs` checks links, indexes, ADR format and the view register; CI asserts the compose invariants. | Prose. The gate cannot read it, which is exactly why claims are pushed into checkable form where possible. |

## Where these conflict

P-02 (fewer components) and the observability stack pull in opposite directions,
and observability won: twelve containers exist purely to watch six. That is a
deliberate exception, because the alternative on a single unattended VM is
finding out about failures from users.
