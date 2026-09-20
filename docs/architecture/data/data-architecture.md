## Data

What is stored, how sensitive it is, where it lives and how long it stays.

### Stores

| Store | Holds | Classification | Residency |
| --- | --- | --- | --- |
| PostgreSQL (app) | Users, tenants, devices, friends, invites, audit events, push subscriptions, and message bodies **as ciphertext**. | Mixed: message bodies are opaque; everything else is cleartext personal data. | The VM's managed disk, EU. |
| Redis | Transient realtime fan-out between WebSocket connections. Persistence is off. | No system of record. Survives no restart. | The VM, in memory. |
| Backblaze B2 (attachments) | Attachment blobs, encrypted in the browser before upload. | Ciphertext only. | `eu-central-003`. |
| Backblaze B2 (backups) | Nightly `age`-encrypted dumps of roles and database. | Ciphertext only; contains the cleartext metadata above once decrypted. | A separate private EU bucket under Object Lock. |
| PostgreSQL (GlitchTip) | Error reports and stack traces. | Operational. Must never carry message content. | The VM's managed disk, EU. |

### The line that matters

The database holds two different kinds of thing and they deserve different
language.

**Message bodies are opaque.** The server stores bytes it cannot interpret. A
database dump, a stolen disk or a leaked backup yields ciphertext.

**Everything around them is not.** Display names, argus-ids, group membership,
who is friends with whom, when each message was sent and how large it was — all
cleartext, because the server must route on it. Calling the whole database
"encrypted" would be false, and is exactly the kind of claim this document
exists to prevent.

### Tenancy

Every tenant-scoped table carries `tenant_id` and an enforced Row-Level Security
policy. The application connects as a role that cannot bypass RLS, and the
tenant identifier is set per transaction from the verified session rather than
from anything the client sends. The multi-tenant machinery is fully enforced
even though the deployment currently runs as one shared tenant pool — privacy
comes from argus-id-only discovery and end-to-end encryption, not from tenant
walls.

### Retention

| Data | Retention | Enforced by |
| --- | --- | --- |
| Messages | Pruned past the retention window. | A scheduled systemd timer on the host. |
| Attachments | Deleted when expired. | A scheduled systemd timer; the blob is removed from B2. |
| Audit events | Pruned on a schedule. | A scheduled systemd timer. |
| Backups | Reaped by a bucket lifecycle rule, not by the worker. | Backblaze B2. The backup credential deliberately has no delete permission. |
| Logs | 7 days. Traces and profiles, 72 hours. | Loki, Tempo and Pyroscope retention settings. |

Backup reaping is a bucket rule rather than a script on purpose: a credential
that can delete backups is a credential ransomware can use.

### Subject rights

Members can export their data and delete their account through the API. What
deletion can reach is metadata and ciphertext held by the server — it cannot
reach copies already decrypted on other members' devices, which is inherent to
end-to-end encryption and stated in the GDPR records rather than left implied.
