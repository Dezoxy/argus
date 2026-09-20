## Integration

Every system outside the argus boundary, what it is relied on for, and what
happens when it is not there.

| System | Relied on for | Failure behaviour |
| --- | --- | --- |
| Cloudflare (edge and tunnel) | All HTTP reachability. TLS, WAF, rate limiting. | Total outage: argus is unreachable. There is no second ingress path, by design ([ADR 6](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/decisions/0006-expose-no-inbound-port-except-the-relay.md)). Calls already in progress continue, because media does not use the tunnel. |
| Cloudflare Access | Identity gate for breakglass, Grafana and GlitchTip. | Those three surfaces become unreachable. Ordinary member and admin traffic is unaffected. |
| Backblaze B2 (attachments) | Attachment upload and download, directly from the browser. | Messages still send and arrive; attachments fail. Text is unaffected because the API never proxies blobs. |
| Backblaze B2 (backups) | Nightly encrypted dumps. | The backup job exits non-zero and raises an alert through the failure notifier. Service is unaffected; the recovery point ages. |
| Azure Key Vault | Every runtime secret, read at boot. | A running system keeps running — secrets are already on tmpfs. A **restart** cannot start until the vault answers. |
| Azure control plane | Running the deploy script; issuing Managed Identity tokens. | Deployment is blocked. The running system is unaffected. |
| GitHub Actions and GHCR | Building, scanning, signing and publishing images. | Releases stop. The running system is unaffected. |
| Browser push services | Content-free notifications to offline devices. | Notifications are silently lost. Messages still arrive when the client reconnects; delivery does not depend on push. |
| Alert receiver | Where firing alerts are delivered. | Alerts are raised and go nowhere — a silent failure of the thing that reports failures. |

### What crosses these interfaces

Only two carry anything derived from user content, and both carry it as
ciphertext: the attachment bucket and the backup bucket. Nothing readable
leaves the boundary.

Push notifications are the interface most likely to be assumed leaky. They are
deliberately **content-free**: the payload carries no sender, no preview and no
conversation identifier — only enough to wake the client, which then fetches and
decrypts locally.

### Coupling worth naming

The Content-Security-Policy pins the exact attachment bucket hostname, so the
browser may reach that origin and no other. That makes the CSP and the bucket
name a **single fact stored in two places**. A deploy-time check fails closed
when they disagree, which is the only reason this is safe to have.
