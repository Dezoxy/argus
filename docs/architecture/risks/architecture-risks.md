## Architecture risks

Known ways this architecture can hurt, with what is already done about each and
what exposure remains. A risk that is fully mitigated is closed and says so; a
risk that is accepted says that too, rather than pretending to be managed.

| ID | Risk | Likelihood basis | Mitigation | Residual exposure | Status |
| --- | --- | --- | --- | --- | --- |
| RISK-001 | Metadata is visible to the operator: who talks to whom, when, how often, how large. | Certain. It follows from storing and routing messages at all. | Discovery is by argus-id rather than phone number or email; the admin surface is metadata-only and audited; no content path exists for admins. | **Accepted and unmitigated in kind.** Cryptography protects content; access control protects metadata, and that is weaker. A member who needs metadata privacy from the operator should not use argus. | Accepted |
| RISK-002 | `ts-mls` is young, with a small ecosystem and few other users. | Moderate. A young library may go unmaintained or need a breaking change. | All use is behind `packages/crypto`, so a replacement touches one package rather than the whole client. | Real. A forced migration would be expensive and would need every client to upgrade together. | Open |
| RISK-003 | A member loses every registered passkey and with it their message history. | Moderate, and certain over a long enough horizon with enough members. | Multi-device enrolment; members are expected to register a second device before they need it. | By design there is no recovery — see [ADR 4](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/decisions/0004-store-no-recoverable-secret-on-the-server.md). The residual is a product and communication problem, not a technical one. | Accepted |
| RISK-004 | The VM is a single point of failure for the application, its data and its own monitoring. | Certain if the host is lost. | Nightly encrypted backups under Object Lock; the stack is portable and provably redeploys elsewhere, which the AWS box demonstrates. | Recovery is a restore, not a failover, and **the restore has never been exercised** ([TD-001](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/technical-debt.md)). The observability stack shares the host, so it cannot report that host's death. | Open |
| RISK-005 | Reachability depends entirely on Cloudflare, and the tunnel's hostname routing lives in their dashboard rather than in git. | Low per year, high impact. | Deliberate: outbound-only ingress is what keeps the VM unexposed ([ADR 6](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/decisions/0006-expose-no-inbound-port-except-the-relay.md)). | A Cloudflare outage takes argus offline with no fallback path, and part of the ingress configuration cannot be restored from this repository. | Accepted |
| RISK-006 | Provider-side configuration — B2 bucket CORS, lifecycle rules, Object Lock retention — is applied by hand and is not in version control. | Moderate. Manual settings drift. | Runbooks describe the settings; a deploy-time check fails closed when the CSP and the bucket name disagree. | A wrong Object Lock retention is unforgiving: in Compliance mode nobody, including the provider, can shorten it. A mis-set value is paid for in storage for the full period. | Open |
| RISK-007 | Dependency vulnerabilities go unaddressed because the security gate is permanently red. | Observed. The OSV scan had failed on `main` continuously, reporting 17 packages affected by 41 advisories. | Cleared: every advisory had a fix within the same major, applied as advisory floors in `pnpm-workspace.yaml` plus one dev-dependency bump. Nothing was ignored or deferred. | The gate is only as good as the next scan. It stays green by being fixed promptly, not by being silenced: `osv-scanner.toml` still allow-lists nothing, so a new advisory fails CI again. | Closed |

### The honest summary

The content-privacy story is strong and structural. The **availability** story is
weak and known: one VM, no failover, and a restore path that has never been
run. RISK-004 with [TD-001](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/technical-debt.md) is the pair to fix first.

RISK-007 was the one blocking the review process itself, and is now closed.
