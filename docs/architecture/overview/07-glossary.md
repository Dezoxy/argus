## Glossary

Terms used throughout these documents, in the sense argus uses them.

| Term | Meaning here |
| --- | --- |
| **argus-id** | The identifier people use to find each other. Not a phone number and not an email address, so discovery does not leak a real-world identity. |
| **Crypto-blind** | The server stores and forwards ciphertext and holds no key that can read it. The defining property of this system. |
| **MLS** | Messaging Layer Security, RFC 9420. The group key-agreement protocol. Provides forward secrecy and post-compromise security for groups, not only pairs. |
| **Forward secrecy** | Compromising a key today does not reveal yesterday's messages. |
| **Post-compromise security** | After an attacker is removed, later messages become unreadable to them again. |
| **Passkey** | A WebAuthn credential bound to this origin, held by the device. Cannot be phished or reused, because there is no shared secret. |
| **PRF** | A WebAuthn extension that derives a stable secret from the passkey. argus uses it to seal the device keystore, so unlocking the account and unlocking the keys are one ceremony. |
| **Device keystore** | The encrypted store of a device's key material. Sealed under the PRF key; never leaves the device in a form the server could open. |
| **Safety number** | A fingerprint two people can compare out of band to confirm no one is impersonating either of them. |
| **Envelope** | The unit the server stores and routes: ciphertext plus the metadata needed to deliver it. |
| **Tenant** | The isolation unit in the database. Every tenant-scoped table carries `tenant_id` under enforced row-level security, even though the deployment currently runs as one shared pool. |
| **RLS** | Row-Level Security. PostgreSQL enforcing per-row visibility in the database, so a missed `WHERE` clause cannot leak across tenants. |
| **FORCE RLS** | RLS applied even to the table's owner, so no role silently bypasses it. |
| **Breakglass** | The emergency administrative login used when no passkey works. Gated at the edge by an independent identity provider, because it exists for when normal authentication has failed. |
| **TURN / coturn** | The relay that carries call media. argus forces every call through it, so neither party learns the other's address. |
| **Cloudflare Tunnel** | An outbound connection from the VM to Cloudflare that carries inbound requests. It is why no HTTP port is open on the server. |
| **Cloudflare Access** | The identity gate in front of the breakglass login, Grafana and GlitchTip. |
| **age** | The file-encryption tool used for database backups. Encrypts to a public recipient key, so the VM can write backups it cannot read. |
| **Object Lock / WORM** | Write-once-read-many storage. Once a backup is written it cannot be deleted or shortened by anyone, which is what makes it ransomware-resistant. |
| **Managed Identity** | A cloud-issued identity the VM proves without holding a stored credential. How secrets are fetched without a secret to fetch them with. |
| **Structurizr** | The tool that renders the architecture model in this folder from text, so the diagrams cannot drift from their source. |
| **ADR** | Architecture Decision Record. One file per significant decision, including the alternatives rejected and the cost accepted. |
