# Reliability and recovery

What fails, what notices, and how service and data come back.

## What fails together

One VM runs everything, so the failure domains are blunt and worth stating
plainly:

| If this fails | These stop |
| --- | --- |
| The VM | Everything: application, database, relay — **and the monitoring that would have reported it**. |
| The managed data disk | PostgreSQL and every other volume. One disk holds them all. |
| Cloudflare or the tunnel | All HTTP reachability. Calls already connected continue; media does not use the tunnel. |
| PostgreSQL | Message send and history. Presence and realtime fan-out survive briefly, then are meaningless. |
| Redis | Live delivery to connected clients. Nothing is lost — Redis holds no system of record — and clients recover on reconnect. |
| Backblaze B2 (attachments) | Attachments. Text messaging is unaffected. |

The first row is the one that matters. Observability shares the host it
observes, so the single most important failure is the one it cannot report. That
is tracked as [TD-004](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/technical-debt.md), and an off-host uptime check
is the fix.

## Backups

Nightly, and unusually well defended for a project this size:

- Two objects per run — cluster roles and the database — each encrypted with
  **`age` to a public recipient key** before upload. The private key is **not on
  the VM**; it lives in Key Vault and is used only at restore.
- The destination is a **separate private EU bucket under Object Lock in
  Compliance mode**. Once written, an object cannot be deleted or shortened by
  anyone — not the key, not the account owner, not the provider.
- The backup credential **cannot delete**. Reaping is a bucket lifecycle rule,
  not a script, because a credential that can delete backups is a credential
  ransomware can use.
- Each run is **signed** with an Ed25519 key the bucket writer does not hold, and
  restore verifies the signature and re-hashes both objects before accepting
  them. A compromised storage key can upload a forged dump; it cannot make
  restore accept one.

## Recovery objectives

| Objective | Target | Evidence |
| --- | --- | --- |
| Recovery point | At most one nightly cycle — up to roughly 24 hours of data. | The timer runs nightly with `Persistent=true`, so a missed run is caught up after downtime. |
| Recovery time | Not measured. | The 2026-06-14 drill proved the procedure, not the duration. A timed drill needs the armed environment. |

That second row is the honest state of this document. Backup *coverage* is
strong; backup *validity* is untested. A successful upload proves the pipeline
ran, not that the result can be restored — see
[TD-001](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/technical-debt.md) and
[QA-06](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/requirements/quality-attributes.md).

## What signatures do not solve

The signing scheme authenticates a backup ("our worker produced this"), not its
freshness ("this is the latest"). An attacker holding the storage key can replay
a genuine older pair as if current. The only anti-rollback anchor is the
immutable upload time recorded by the bucket, which means the restore runbook
needs the operator to know the compromise window. Signatures and timestamps are
both required, and neither is sufficient alone.

## No high availability

There is none, deliberately ([ADR 5](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/decisions/0005-run-on-one-vm-with-docker-compose.md)).
Recovery from host loss is a rebuild and restore, not a failover. The stack's
portability makes the rebuild routine — the AWS box demonstrates it — but the
restore step remains unproven.
