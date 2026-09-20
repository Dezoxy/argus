# Quality attributes

Measurable requirements, each written as a scenario rather than an adjective.
"Secure" is not a requirement; "a full host compromise does not disclose message
content" is one, because it can be argued about and tested.

**Target versus measurement.** Every row below is a *target*. Where evidence
exists it is named; where it does not, the row says so. A target with no
evidence is a claim, not a result.

| ID | Scenario | Response and target | Evidence today |
| --- | --- | --- | --- |
| QA-01 | An attacker gains root on the VM and reads its disks and backups. | Message content stays unreadable. No key that opens a message exists on the server or in a backup. | Enforced by design: the API never decrypts. Not independently verified — the crypto review gate is open. |
| QA-02 | A member or one of their devices is removed from a group. | They cannot read messages sent after removal. | MLS provides it; exercised by the multi-device enrolment and group-membership tests. Not independently reviewed. |
| QA-03 | An attacker phishes a member's credential or reuses a password from another breach. | Neither is possible: no password exists and passkeys are origin-bound. | Structural — there is no password to steal. See [ADR 3](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/decisions/0003-authenticate-with-passkeys-only.md). |
| QA-04 | The VM's public address is port-scanned. | Only the call-relay ports answer. No unauthenticated HTTP service is reachable. | CI asserts no Compose service publishes a host port and that coturn is the only host-network service; the firewall's only inbound Allow rules are TURN. |
| QA-05 | The attachment storage provider, or anyone who obtains that bucket, reads its contents. | They obtain ciphertext only. | Attachments are encrypted in the browser before upload; the API only mints presigned URLs. |
| QA-06 | The VM is lost entirely. | Service is restored from backup rather than failed over. Recovery point is at most one nightly cycle. | Backups are taken, encrypted and Object-Locked. **A full restore has not been exercised.** A successful backup is not a restore test. |

## The one that is weakest

QA-06. Backup coverage is good and the anti-tamper story is unusually strong,
but an untested restore is a hypothesis. Until a restore is performed into a
scratch database and the result checked, the recovery target is aspirational.
That gap is tracked as [TD-001](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/technical-debt.md).
