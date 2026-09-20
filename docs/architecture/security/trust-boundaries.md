## Trust boundaries

Where control changes hands, and what is checked at each crossing.
[Security architecture](security-architecture.md) covers the controls
themselves — what is defended, from whom, and by what. The
[AccessPaths](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/README.md#view-register) view draws the three entry paths; this
document says what each boundary actually enforces.

### The boundaries

| Boundary | What crosses it | What is enforced |
| --- | --- | --- |
| Member device to everything else | Ciphertext only. Plaintext, message keys and the device keystore never cross. | The keystore is sealed under the WebAuthn PRF unlock key. Nothing can decrypt it off the device. |
| Internet to the VM, HTTP | Every request, down an outbound-only Cloudflare Tunnel. | TLS, WAF and rate limiting at the edge. No inbound HTTP port exists on the VM. |
| Internet to the VM, media | Call media on the TURN ports. | The only inbound Allow rules in the firewall. Relay credentials are short-lived HMAC, minted per call. |
| Cloudflare Access to the privileged surfaces | The breakglass login, Grafana, GlitchTip. | An Access JWT the API verifies against the issuer's JWKS. The ingress returns 404 — not 403 — when the JWT is absent, so the path does not confirm it exists. |
| API to database | Every query. | A non-bypass PostgreSQL role, with the tenant identifier set per transaction and FORCE RLS on every tenant-scoped table. |
| VM to object storage | Encrypted attachments, encrypted backups. | Separate buckets and separate credentials. The backup key can write but cannot delete. |
| VM to secret storage | Runtime secrets, at boot. | Managed Identity, no stored credential. Secrets land as tmpfs credential files, never environment variables. |

### The part people misread

**`/api/admin/*` is not behind Cloudflare Access.** The breakglass login is;
the ordinary admin surface is not. This is deliberate and documented in both the
ingress configuration and the deploy notes, and it is the single most
misunderstood detail in this system.

The reasoning: an admin is an ordinary authenticated member whose role happens to
be `admin`, so their requests are authorised in the application, by a guard that
re-reads the role from the database under RLS and checks session revocation.
Breakglass is different in kind — it is the path that exists *because* normal
authentication has failed, so it cannot rely on it, and therefore gets an
independent gate at the edge.

Putting the ordinary admin surface behind Access as well would add a second
identity system in front of a path that already authenticates properly, and
would make the two paths look equivalent when they are not.

### What the boundaries do not protect

Metadata. The database holds who talks to whom, when, and how much, in
cleartext, because routing requires it. Every boundary above protects it with
access control rather than cryptography, and that is a weaker promise. It is
recorded as [RISK-001](https://github.com/Dezoxy/secmes/blob/main/docs/architecture/risks/architecture-risks.md) rather than glossed.
