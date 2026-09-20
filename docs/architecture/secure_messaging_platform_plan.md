# argus — Architecture

> **What this is:** the canonical "how the system is built" doc. It describes
> **what exists today**, not what was once planned. Two later course-corrections
> are already folded in: Kubernetes/AKS was dropped for a single VM + Docker
> Compose (2026-06), and the **private-messenger redesign** (2026-06/07)
> replaced the enterprise-SaaS shape — Zitadel OIDC, per-tenant SSO, Stripe
> billing, self-serve workspaces, the browsable user directory — with an
> invite-only, passkey-only messenger. The earlier AWS/Kubernetes/enterprise
> cuts live in `git log` and [`../archive/`](../archive/); do not follow them.
>
> **Phasing is not here.**
> [`../planning/roadmap/README.md`](../planning/roadmap/README.md) is canonical
> for what is done and what is left. **Rules** are in `AGENTS.md`. This doc is
> the shape of the system.

---

## 0. Executive Summary

An **end-to-end-encrypted messenger** delivered as an installable **PWA** (no
app stores). The server is a **crypto-blind delivery layer**: it stores
ciphertext, fans out real-time messages, brokers public keys, and relays call
media — it can never read message content.

Access is **invite-only**: an admin mints a one-time registration code, the user
redeems it and sets up a **passkey**. There is no email, no password, no
external IdP, and no self-serve signup.

**Stack as built:**

| Layer            | Choice                                                                                          |
| ---------------- | ----------------------------------------------------------------------------------------------- |
| Language         | **TypeScript**, end-to-end (strict, ESM, pnpm workspaces)                                       |
| Frontend         | **React + Vite**, built as a **PWA**                                                            |
| Backend          | **NestJS** (`apps/api`) — HTTP + the WebSocket gateway in one service                           |
| Realtime         | **WebSocket** gateway, **Redis** pub/sub backplane                                              |
| Database         | **PostgreSQL** + **FORCE Row-Level Security** on every tenant-scoped table                      |
| Client crypto    | **MLS (RFC 9420)** via [`ts-mls`](mls-library-selection.md) — never hand-rolled                 |
| Identity / auth  | **Passkeys (WebAuthn)** + **API-minted EdDSA session tokens**. No external IdP.                 |
| Calling          | **WebRTC** 1:1 audio, **always relayed** through self-hosted **coturn**                       |
| Object storage   | **Backblaze B2** (S3-compatible, EU `eu-central-003`, private buckets) — MinIO locally          |
| Orchestration    | **Single Azure VM** (`Standard_B2ms`, `germanywestcentral`) + Docker Compose                    |
| Ingress / TLS    | **Cloudflare Tunnel** (no public HTTP ports) + Cloudflare edge TLS/WAF; **Caddy** internally    |
| Observability    | Self-hosted **Prometheus · Alertmanager · Grafana · Loki · Alloy · Tempo · Pyroscope · GlitchTip** |
| Deploy           | Tag-triggered **GitHub Actions → Azure OIDC → VM run-command** (no SSH, no open ports)          |

**Why Azure, and the privacy trade being accepted:** Azure gives one low-cost
**VM**, **Key Vault** for secrets, and cloud skills that transfer — without the
K8s ops a solo dev can't justify. The honest cost: Azure is **US-owned**, so the
privacy story is _"E2EE (the cloud only ever holds ciphertext + metadata) + EU
Data Boundary + a German region"_ rather than _"EU-owned provider"_. Defensible,
but a notch weaker than Hetzner/Scaleway on pure sovereignty. The stack is plain
Docker Compose, so moving the VM to an EU-owned host later is a re-provision,
not a rewrite.

---

## 1. Product Goal & Scope

**Goal:** a private messenger where the operator is **technically incapable** of
reading message content, and where membership is closed — you get in because
someone already inside handed you a code.

**Shipped today:**

- Invite-code registration → **passkey** setup; **passkey-only** login thereafter
- Immutable, shareable **argus-id** (`argus-<16 chars>-<animal>`); find people
  by **exact argus-id only**
- **Friends list** — the durable contact source that survives a PWA reinstall
- **1:1 and group** E2EE text messaging over MLS
- **Encrypted image attachments** (client-side AES-GCM → presigned B2)
- **Multi-device** — a new device is approved by an existing trusted device,
  after a fingerprint check
- **1:1 audio calls** — WebRTC, always relayed via coturn in V1, signaling
  carried as MLS ciphertext
- **Safety-number (fingerprint) verification** against key substitution
- Real-time delivery + offline catch-up, delivery/read receipts, **web push**
- Per-user privacy toggles (read receipts, typing indicators, link previews; a
  relay-only call preference is stored for V1.1)
- **Metadata-only admin panel** (devices + audit; never content) and a
  **breakglass** admin login
- **GDPR** export + erasure; **90-day** server-side message retention with a
  DB-enforced prune

**Explicitly out of scope today:**

- **Video calls** — V1.1; the API schema pins `media: 'audio'` and widens later
- Group calls (1:1 only; needs an SFU)
- Federation / cross-org messaging
- Server-side message search — impossible under E2EE; client-side only
- Compliance / eDiscovery mode — a future, opt-in feature (§15)
- Bots / AI features
- Native mobile apps — planned, gated on a crypto spike ([`../planning/mobile/`](../planning/mobile/))

---

## 2. Core Principle

> The server delivers messages; it never owns their content.

- Content is encrypted **on the client** before it touches the network.
- The database stores **ciphertext**; object storage stores **encrypted blobs**;
  coturn relays **encrypted media** it cannot interpret.
- Admins see **security metadata**, never plaintext.

The backend manages: authentication, authorization, tenant isolation, the public
**key directory**, message routing & storage, attachment references, TURN
credential minting, audit events, and operations. It never manages: plaintext,
user private keys, or decryption of conversations.

---

## 3. Security Model

### 3.1 What "E2EE" means here (device-local keys)

- A user may have **N devices**. Each new device is added by **approval from an
  existing trusted device** after an out-of-band fingerprint check
  (`threat-models/multi-device-enrollment.md`). MLS private keys live in
  **IndexedDB**, sealed under the per-passkey PRF unlock key.
- There is **no key backup and no recovery**: every new device is provisioned
  **fresh** (no prior history — MLS forward secrecy), either via enrollment from
  an existing device or, for a user with **no** remaining enrolled device, via a
  new registration code (§3.4). "New phone / new browser" is always a fresh
  device.

### 3.2 The honest PWA caveat (read this twice)

A web app delivers the encryption code on every load, so a **fully compromised
server could ship malicious JavaScript** and capture plaintext. Native apps
avoid this; a pure PWA cannot fully escape it. It can only be narrowed:

- Strict **Content-Security-Policy** + **Subresource Integrity** (the browser rejects tampered scripts)
- **Service worker** caches the app shell, so the code changes rarely and
  visibly; the SW's own integrity is inlined at build time and checked in CI
  (`apps/web/scripts/check-sw-integrity.mjs`)
- Published bundle hashes on the in-app transparency page, for independent verification
- Treat the **deploy pipeline as the #1 attack surface** — sign and scan every
  image, gate every rollout

Be honest with users: this is "very strong privacy", not "uncompromisable". It
is the same trade Signal made when it chose native apps. Acceptable for a
privacy-first PWA; do not oversell it. See
`threat-models/code-delivery-integrity.md`.

### 3.3 Crypto: build on a standard, never hand-roll

- **Protocol: MLS (RFC 9420)** via [`ts-mls`](mls-library-selection.md) (MIT,
  pure TypeScript). Chosen over the Signal protocol because MLS is the modern
  IETF standard and is **group-ready**, so group chat was an increment rather
  than a rewrite.
- **Do not** compose a scheme from primitives. All cryptography lives in
  `packages/crypto`; primitives must not appear elsewhere (AGENTS.md invariant
  #4).
- The server stores MLS **KeyPackages** (public), ciphertext messages,
  ciphertext commits, and Welcome messages for offline delivery. All of it is
  opaque to the server.

### 3.4 Key backup & recovery — there is none, by design

The original passphrase / Argon2id / server-stored key-backup design was
**removed** (migration `0040_drop_key_backups.sql`;
`packages/crypto/src/key-backup.ts` deleted). The shipped model seals the device
keystore directly under a per-passkey **WebAuthn-PRF** key — no passphrase, no
Argon2, and **no recoverable secret on the server**.

- The keystore (IndexedDB, currently schema v8) is sealed at rest under the PRF
  unlock key: a non-extractable AES-256-GCM `CryptoKey` that exists in memory
  only.
- A lost passkey or an evicted PWA store is a **fresh start** — an admin mints a
  new registration code, the user re-registers as a **new identity**, and starts
  with no history.
- This trades recoverability for a strictly smaller attack surface (no
  server-held key ciphertext to steal or brute-force) and is consistent with MLS
  forward secrecy. See `threat-models/prf-keystore-unlock.md` and
  `threat-models/key-model.md`.

### 3.5 Auth ↔ crypto boundary

**A passkey is not an MLS device key.** The passkey authenticates _who you are_:
the server stores its WebAuthn **public** key, which is safe for
crypto-blindness because it is not message key material. The MLS device
signature key is the per-device **E2EE identity** and never leaves the client.
The two systems stay independent — losing one does not compromise the other, and
a lost passkey means a new MLS identity too.

---

## 4. Tenancy

The multi-tenant machinery is **retained and enforced**, but the deployment is
**effectively single-tenant**.

- **Model:** shared PostgreSQL; every tenant-scoped table carries `tenant_id`
  with **`ENABLE` + `FORCE` RLS**. The app sets `app.tenant_id` per transaction
  (`withTenant()` in `apps/api/src/db/index.ts`), so Postgres rejects
  cross-tenant reads even when application code has a bug (AGENTS.md invariant
  #3).
- **The guard is catalog-driven, not a hand-written list.**
  `apps/api/src/db/rls-coverage.spec.ts` enumerates every ordinary table in
  `public` from the live catalog and fails if one is not tenant-isolated by the
  exact policy shape. A new table without a policy turns it red automatically.
  Four tables sit on a justified allowlist (`schema_migrations`,
  `user_tenant_index`, `webauthn_challenges`, `stripe_events`).
- **One tenant in practice:** every user is bound to a single fixed
  `DEFAULT_TENANT_ID` (`apps/api/src/auth/breakglass.service.ts`). Privacy comes
  from **argus-id-only discovery + E2EE**, not from tenant walls. Keeping RLS
  costs a few lines and leaves real multi-tenancy reversible; removing it would
  be a multi-month teardown of the security boundary.
- **No per-tenant IdP config, no plans, no billing.** Those columns survive as
  inert residue from migration `0039_decommission_enterprise.sql` and are slated
  for a later cleanup migration.

---

## 5. Architecture Overview

```text
        Every platform (installed PWA: iOS/Android/Win/macOS/Linux)
                        |                              |
                        | HTTPS / WSS                  | UDP/TLS (media)
                        v                              |
      Cloudflare edge (TLS, WAF, rate-limit)           |
                        |                              |
                        | Cloudflare Tunnel            |  (cannot ride the tunnel — UDP)
                        | (cloudflared dials OUT)      |
                        v                              v
    ========== single Azure VM (germanywestcentral) ==========
    |            Docker Compose stack                        |
    |                                                        |
    |   cloudflared -- caddy (plain HTTP, single origin)      |
    |                    |                                   |
    |                    v                                   |
    |            PWA static  +  api (NestJS: HTTP + WS)       |
    |                              |        |                |
    |                              v        v                |
    |                          postgres    redis              |
    |                         (self-host) (backplane)         |
    |                                                        |
    |   coturn (TURN relay — ciphertext media only)           |
    |   prometheus · alertmanager · grafana · loki · alloy    |
    |   tempo · pyroscope · exporters · glitchtip             |
    ==========================================================
                              |
                              v
                Backblaze B2 (EU eu-central-003)
          encrypted image blobs + encrypted DB backups (private)

  Secrets: Azure Key Vault, fetched by the VM's Managed Identity as credential files (tmpfs).
  Network: the Azure NSG denies all inbound except the coturn media ports; everything else is
           outbound-only via the Cloudflare Tunnel.
```

---

## 6. VM Deploy Architecture

Full operational detail — rollout, rollback, health gates — lives in
[`deploy.md`](deploy.md). This section is the shape only.

### 6.1 The VM

- **Host:** one Azure VM (`Standard_B2ms` — 2 vCPU / 8 GiB, burstable) in
  **Germany West Central** (`germanywestcentral`). Every Azure resource is
  pinned to the same region.
- **Stack:** **Docker Compose** (`compose.prod.yaml`) runs self-hosted
  **Postgres + Redis** alongside `api`, `caddy` (which also serves the PWA),
  `cloudflared`, `coturn`, and the full observability stack. One container per
  service — no autoscaling; scale the VM up if needed.
- **Native workers:** four jobs run on the VM as **systemd timers**, not
  containers — nightly encrypted DB backup (`infra/backup/`), expired-attachment
  reaper (`infra/cleanup/`), audit-event prune (`infra/audit-prune/`), and the
  90-day message-retention prune (`infra/retention/`). Each connects as its own
  least-privilege Postgres role.
- **Identity:** the VM's **Managed Identity** reads secrets from **Azure Key
  Vault** with no static creds; secrets land as **credential files** in a tmpfs,
  never in env at rest (AGENTS.md invariant #5).

### 6.2 Ingress, TLS & isolation

- **Ingress = Cloudflare Tunnel.** `cloudflared` dials **outbound**, so no
  inbound HTTP port is opened. Cloudflare is the edge: **TLS termination, WAF,
  rate-limit**.
- **The one exception is coturn.** WebRTC media is UDP, which a Cloudflare
  Tunnel cannot carry, so the TURN ports are the only inbound rule in the NSG.
  coturn is the most exposed service in the stack and is hardened accordingly —
  ephemeral HMAC credentials, no long-lived users, peer ACLs. See
  `threat-models/voip-turn.md` and
  [`../runbooks/voip-turn.md`](../runbooks/voip-turn.md).
- **Internal proxy = Caddy** (plain HTTP, single origin): serves the PWA and
  proxies `/api` and `/ws`. TLS is Cloudflare's job (no cert-manager, no
  Let's-Encrypt-on-host).
- **Network isolation = Azure NSG** + Cloudflare. **No service publishes a host
  port**; `coturn` alone runs on the host network so it can reach the TURN
  ports. Both facts are asserted by the `compose-guard` CI job.

### 6.3 CD & secrets

- **CD is driven by GitHub Actions + Azure OIDC** through the Azure control
  plane — no SSH, no open ports, and it works before the tunnel exists. The
  pipeline builds, scans (Trivy), and **signs** (cosign keyless) both images,
  pushes to GHCR, then runs the deploy script on the VM: pull →
  **migrate-before-serve** → `docker compose up`.
- **Secrets = Key Vault + Managed Identity**, delivered as files. `db:migrate`
  runs with the owner credential (never the runtime `argus_app` role) before the
  new container takes traffic.

### 6.4 Container security (applied to every service)

```text
non-root where the image allows, read-only root filesystem, cap_drop: ALL, no-new-privileges
resource limits on every service
data services (postgres/redis) on the private Docker network only — never published
image scanning (Trivy) in CI; only signed + scanned images deploy
short-lived OIDC tokens for CD; no long-lived cloud keys on the VM
```

### 6.5 IaC

Terraform is split by concern, deliberately:

- `infra/azure/terraform/` — the production target: RG, VNet, NSG, the VM, Key
  Vault, Managed Identity, and the GitHub-OIDC deploy role.
- `infra/stack/` — the **cloud-agnostic** runtime the VM actually runs: deploy script, Key Vault
  secret-fetch, Caddy, coturn, observability, GlitchTip.
- `infra/aws/` — a **parallel EC2 experiment** (`t3.medium`, `eu-central-1`) on
  its own tag namespace and kill-switch. Not production; it exists to prove the
  stack is portable and to shake out runtime issues.
- `infra/b2/` — the Backblaze bucket CORS policy.

---

## 7. Data Model

21 tables are modeled in `apps/api/src/db/schema.ts`; **19 of them are
tenant-isolated by RLS**, and two are on the justified allowlist (§4). The
database holds two more that carry no app model — `schema_migrations` and the
inert `stripe_events` — also allowlisted. Shapes below are abbreviated; the
source of truth is `schema.ts` and the numbered migrations in
`apps/api/src/db/migrations/`.

```text
-- identity & auth ------------------------------------------------------------
tenants(id, name, created_at)                         # one row in practice (§4)

users(id, tenant_id, external_identity_id, argus_id, email, display_name,
      avatar_seed, status, role, privacy_read_receipts,
      privacy_typing_indicators, privacy_link_previews, call_relay_only,
      created_at)
      # argus_id is immutable — enforced by a BEFORE UPDATE trigger, not a grant
      #   (Postgres cannot subtract one column from a table-level UPDATE grant).
      # email + external_identity_id are INERT: nulled by 0039, kept for a later drop.

user_tenant_index(sub, tenant_id, created_at)         # sub -> tenant routing; read BEFORE
                                                      # tenant context exists. No RLS (allowlisted).
webauthn_credentials(id, tenant_id, user_id, credential_id, public_key, counter,
                     aaguid, backed_up, transports, device_label, created_at,
                     last_used_at)                    # COSE PUBLIC key; server-auth only, NOT E2EE
webauthn_challenges(ceremony_id, challenge_hash, purpose, argus_id, invite_id,
                    expires_at)                       # ephemeral, delete-on-use; no RLS (allowlisted)
auth_sessions(id, tenant_id, user_id, sub, refresh_token_hash, created_at,
              last_used_at, expires_at, revoked_at)   # refresh state only — access tokens are stateless
admin_credentials(id, tenant_id, user_id, username, password_hash, salt,
                  kdf_params, failed_attempts, locked_until, …)   # breakglass; Argon2id
tenant_invites(id, tenant_id, created_by, token_hash, invitee_email, expires_at,
               accepted_by, accepted_at, revoked_at, created_at)  # registration codes
                                                      # invitee_email is INERT (nulled by 0039)

-- devices & keys -------------------------------------------------------------
devices(id, tenant_id, user_id, signature_public_key, is_provisional, created_at)
        # provisional = published but not yet approved by an enrolled device
device_enrollments(id, tenant_id, user_id, requesting_device_id,
                   approved_by_device_id, fingerprint, status, created_at,
                   resolved_at, expires_at)           # approve-from-trusted-device
key_packages(id, tenant_id, device_id, key_package, claimed_at, created_at)
        # MLS KeyPackages — public, opaque, claimed once

-- messaging ------------------------------------------------------------------
conversations(id, tenant_id, created_by, is_direct, created_at)
        # no name/title column — that would be plaintext metadata
conversation_members(id, tenant_id, conversation_id, user_id, joined_at)
        # membership is add/remove by row; there is no role or removed_at column
conversation_commits(id, tenant_id, conversation_id, sender_user_id,
                     client_commit_id, epoch, commit, created_at)   # MLS commits (ciphertext)
conversation_welcomes(id, tenant_id, conversation_id, recipient_user_id,
                      recipient_device_id, sender_user_id, welcome, ratchet_tree,
                      created_at)                     # offline Welcome; consumed on join
messages(id, tenant_id, conversation_id, sender_user_id, client_message_id,
         ciphertext, alg, epoch, attachment_object_key, created_at)
        # pruned at 90 days; sender_user_id nullable after GDPR erasure
conversation_receipts(id, tenant_id, conversation_id, user_id,
                      delivered_through_message_id, read_through_message_id, …)
        # high-water marks per (conversation, member) — metadata only
attachments(id, tenant_id, conversation_id, object_key, byte_size, uploaded_by,
            created_at, expires_at)
        # keyed to the CONVERSATION, not to a message; the content key lives only
        # in the MLS envelope, never here
friendships(id, tenant_id, user_low_id, user_high_id, status, requested_by,
            expires_at, created_at, resolved_at)
        # CANONICAL PAIR ordering — user_low_id = least(a,b), user_high_id = greatest(a,b),
        # so one row per pair regardless of direction. Accepted-only: a decline or cancel
        # is a hard DELETE (no rejection ledger); requested_by is NULLed on accept.
push_subscriptions(id, tenant_id, device_id, user_id, endpoint, p256dh, auth, …)

-- operations -----------------------------------------------------------------
audit_events(id, tenant_id, event_type, actor_sub, ip, user_agent, metadata,
             created_at)                              # append-only; pruned on a timer
```

**There is no call table.** Calls persist **nothing** — no participants, no
timestamps, no duration. Signaling is relayed in memory over the WebSocket, and
TURN credentials are minted per attempt with a 600-second TTL. The only durable
call-related state is the per-user `call_relay_only` preference.

**Removed, with inert residue:** `key_backups` (removed by `0040`),
`tenant_sso_configs` (removed by `0039`). `stripe_events` and the
`tenants.plan_*` / `stripe_*` columns still exist but nothing reads or writes
them.

---

## 8. Identity & Auth

There is **no external IdP**. The API is the identity provider.

**Registration** — invite-only, three steps:

1. An admin mints a one-time **registration code** (32 bytes, SHA-256 at rest,
   single-use atomic redeem, 7-day TTL). A dedicated RLS carve-out exposes
   exactly one invite row via a transaction-local `app.invite_token_hash` GUC —
   the pattern for "look up a code before any session context exists".
2. The client redeems the code and runs a **WebAuthn registration** ceremony.
   The server stores the credential's **public** key.
3. The server mints an immutable **argus-id** — `argus-<16 unambiguous
   chars>-<animal>`, CSPRNG-generated — and a matching `users` row. `argus_id`
   cannot be changed; a `BEFORE UPDATE` trigger enforces it, because Postgres
   cannot subtract one column from a table-level UPDATE grant.

**Login** — passkey only. The client auto-tries a discoverable passkey; if none
exists, the user falls back to "I have a registration code". No password, no
email, no magic link.

**Sessions** — the API mints and verifies **its own** tokens:

- A **10-minute EdDSA (Ed25519) access token**, held in memory only. The signing
  key is a Key Vault credential file (an ephemeral pair in dev, so sessions do
  not survive a restart).
- A **30-day refresh token** in an `HttpOnly` + `SameSite=Strict` cookie, hashed
  at rest in `auth_sessions`, paired with a CSRF header. This is what makes
  "stay logged in across a reload" work.
- `sub` is the identity spine: **`"argusid:" + argus_id`**. It is the PK of
  `user_tenant_index`, the lookup key in `requireUser()`, the match key in
  `AdminGuard`, the room key in the WS gateway, and the audit actor. A new
  identity is a new `sub` — which is exactly why "lost passkey = fresh start"
  falls out for free.

**Discovery** — exact **argus-id lookup only** (`GET /users/lookup`). The
browsable directory was removed; users cannot be enumerated.

**Breakglass admin** — a single admin **username + password** (Argon2id,
lockout, fully audited), bootstrapped from Azure Key Vault. It exists so the
operator can reach the admin panel when no passkey works. See
`threat-models/breakglass-admin.md`.

**Authorization** — a global deny-by-default JWT guard, with `@Public()` /
`@AllowUnbound()` as the explicit opt-outs; `AdminGuard` re-reads the role from
the database rather than trusting the token. Messaging is **friendship-gated**:
a conversation cannot be started with a non-friend.

---

## 9. Message, Image & Call Flows

### Text

```text
1. Client fetches the recipient's MLS KeyPackage from the key directory.
2. Client encrypts the message (MLS) locally.
3. Client sends ciphertext to api.
4. api authorizes the sender (membership + friendship), writes ciphertext, emits a delivery event.
5. The WS gateway pushes ciphertext to the recipient (or it waits, durable, until reconnect).
6. Recipient decrypts locally.
```

### Image

```text
1. Client generates a random content key and encrypts the image locally (AES-GCM).
2. Client requests a presigned upload URL from api (server-generated, tenant-namespaced object key).
3. Client uploads the encrypted blob directly to Backblaze B2.
4. Client sends an E2EE message carrying the encrypted attachment metadata
   (object key + content key, wrapped for the recipients).
5. Recipient fetches a presigned download URL, downloads, decrypts locally.
```

Object storage: **private buckets, no public URLs, short-lived presigned access
only**. Presigned URLs are never logged (AGENTS.md invariant #2). Expired
attachments are reaped by the `infra/cleanup/` timer.

### Audio call

```text
1. Caller POSTs /calls — api checks friendship + membership, returns a callId and
   ephemeral TURN credentials (HMAC-derived, 600 s TTL, minted in packages/crypto).
2. api rings the callee over the WebSocket. No call row is written.
3. Both peers exchange SDP + ICE as MLS ciphertext through the existing conversation —
   the server relays signaling frames it cannot read, and each frame is sender-bound.
4. Media flows over WebRTC. ICE is forced through coturn, so neither peer ever learns
   the other's IP address.
5. On hangup, everything is gone — nothing was persisted.
```

`iceTransportPolicy: 'relay'` is set **server-side** and never overridden by the
client. In V1 it is **unconditional**: the per-user `call_relay_only` preference
is stored and readable but deliberately ignored, so no user can accidentally (or
be tricked into) leaking their IP. Honouring the opt-out is a V1.1 decision. See
`threat-models/voip-calling.md`.

---

## 10. Realtime Design

- The WebSocket gateway lives inside the `api` service; on the single-VM
  deployment that is one process.
- **Redis pub/sub** is the realtime bus. It would fan out across instances if
  the API ever ran more than one. It is **not** the rate-limiter store: rate
  limiting is in-memory on the single instance
  (`apps/api/src/rate-limit/rate-limit.constants.ts`), so limits reset on
  restart. Moving that store to Redis is tracked as
  [TD-002](risks/technical-debt.md).
- Cloudflare and Caddy proxy the WebSocket upgrade through to the gateway.
- WS auth is a first-frame `auth` message verified by the same `auth.verify()`
  the HTTP guard uses.
- Offline users: messages persist as ciphertext and are delivered on reconnect.
- Presence and typing indicators are **per-user opt-out** and privacy-defaulted.

---

## 11. Observability (without leaking content)

**Log:** request id, tenant id, user id, service, operation, status, latency,
error category, message id. **Never log:** message text, image data, plaintext
metadata, private keys, tokens, full auth headers, presigned URLs. A Semgrep
rule plus a CI label guard (`scripts/check-observability-log-labels.sh`) enforce
this mechanically.

The stack is fully self-hosted on the VM (`infra/stack/observability/`):

| Component                             | Role                                                          |
| ------------------------------------- | ------------------------------------------------------------- |
| **Prometheus**                        | metrics scrape + storage                                      |
| **Alertmanager**                      | alert routing (infra alerts, SLO multi-burn-rate)             |
| **Grafana**                           | dashboards (service, infra, SLO, security, logs)              |
| **Loki** + **Alloy**                  | log aggregation + shipping, with alerting rules on security events |
| **Tempo**                             | distributed traces, linked from metrics via exemplars         |
| **Pyroscope**                         | continuous profiling                                          |
| **postgres-exporter**, **redis-exporter** | data-service metrics                                      |
| **GlitchTip**                         | error tracking (self-hosted, Sentry-compatible)               |

Roadmap and per-idea notes: [`../planning/observability-improvements/`](../planning/observability-improvements/).

---

## 12. CI/CD

```text
push / PR         ci.yml         build-test (typecheck · unit tests · migrations · OpenAPI · SW-SRI)
                                 e2e (Playwright)
                                 compose-guard (no published host ports; exactly one host-network
                                   service; CSP connect-src pinned; observability log labels)
                  security.yml   Semgrep (custom rules) · OSV · gitleaks · Checkov · 42Crunch audit
                  codeql.yml     CodeQL
                  claude.yml     the @claude PR reviewer
nightly           dast.yml       DAST

tag v*.*.*        cd.yml         build → Trivy → SBOM → cosign sign → GHCR
                                 → VM run-command → migrate-before-serve → compose up
tag aws-v*.*.*    cd-aws.yml     the same, against the parallel EC2 experiment box
```

Both deploy workflows sit behind **two gates**: a repo-variable kill-switch (`vars.ENABLE_DEPLOY` /
`vars.ENABLE_DEPLOY_AWS`) and a GitHub **Environment approval**. The version tag _is_ the image tag, so a
running container is always traceable to a git tag.

Locally, **lefthook** runs gitleaks + ESLint + Prettier + Semgrep on commit, and
typecheck + tests on push.

---

## 13. Repository Structure

```text
apps/
  api/                  # NestJS — HTTP + WS gateway, crypto-blind routing, identity,
                        #   key directory, friends, calls, admin, GDPR
  web/                  # React + Vite PWA — chat, calls, device linking, admin, v2 UI sketch
packages/
  contracts/            # shared TS types + Zod schemas (the E2EE envelope) — validated at every boundary
  crypto/               # MLS (ts-mls) wrapper, device keys, safety numbers, TURN credential minting
infra/
  azure/terraform/      # the production target (VM, NSG, Key Vault, Managed Identity, OIDC role)
  aws/                  # the parallel EC2 experiment (own tag namespace + kill-switch)
  stack/                # cloud-agnostic VM runtime: deploy · secrets · caddy · coturn ·
                        #   observability · glitchtip
  backup/ cleanup/      # systemd timers: nightly encrypted DB backup · attachment reaper
  audit-prune/          # systemd timer: audit-event prune
  retention/            # systemd timer: 90-day message prune
  notify/ b2/           # failure alerting · Backblaze bucket CORS
docs/                   # architecture · planning · operations · threat-models · reviews · gdpr
scripts/                # repo guards (CSP, dockerignore/secret sync, log labels, PWA build verify)
compose.yaml            # dev stack (Postgres, Redis, MinIO, api)
compose.prod.yaml       # prod stack (+ caddy, cloudflared, coturn, observability, glitchtip)
.github/workflows/      # ci · security · codeql · dast · cd · cd-aws · claude
```

`packages/contracts` is the concrete payoff of going TypeScript end-to-end —
client and server can never disagree on the encrypted envelope.

---

## 14. Threat Model

Per-feature notes live in [`../threat-models/`](../threat-models/); this is the summary sheet.

| Threat                                                | Protection                                                                                                                                                                                          |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Database leak                                         | Ciphertext only; FORCE RLS limits blast radius; no key material at rest                                                                                                                             |
| Object storage leak                                   | Client-side encryption + private buckets + presigned-only access                                                                                                                                    |
| Cross-tenant access                                   | Postgres RLS + per-transaction tenant context + a catalog-driven coverage guard                                                                                                                     |
| Stolen infra credentials                              | Managed Identity + Key Vault, no long-lived keys on the VM, audit logs                                                                                                                              |
| Compromised container                                 | NSG + Cloudflare edge; data services private; non-root, read-only FS, dropped caps                                                                                                                  |
| Compromised admin                                     | Metadata-only admin surface, breakglass lockout + full audit trail, no content path                                                                                                                 |
| Lost device / passkey                                 | Fresh start by design (§3.4); device revocation; KeyPackage invalidation                                                                                                                            |
| Malicious insider (the operator)                      | E2EE means content is unreadable — provable, not promised                                                                                                                                           |
| Key substitution / MITM                               | Safety-number (fingerprint) verification; key-directory threat note                                                                                                                                 |
| Metadata exposure (who talks to whom, when, sizes)    | Inherent to a hosted delivery layer; minimized (opaque conversation ids, no titles, pseudonymous argus-ids, IDs-only logs) and stated as accepted residual — `threat-models/metadata-exposure.md`     |
| Peer IP disclosure during a call                      | Relay-only by default, enforced server-side; opt-in direct P2P only                                                                                                                                 |
| Malicious JS injection                                | CSP + SRI + service-worker integrity + a hardened, signed pipeline (§3.2)                                                                                                                            |
| User enumeration                                      | Exact-argus-id lookup only; no directory; uniform responses                                                                                                                                         |
| Unbounded ciphertext growth                           | 90-day retention prune, enforced by a DB-scoped role that cannot read content                                                                                                                       |

---

## 15. Privacy vs. Compliance Positioning

Maximum-privacy E2EE means the operator **cannot** offer message archival,
eDiscovery, legal hold, or admin content audit. That is the point, and it is the
differentiator — but it does close the door on anyone who _requires_ content
retention.

**Position:** stay privacy-first. Keep a documented, opt-in, **per-tenant
compliance mode** as a future feature if that market ever matters
([`../planning/roadmap/09-backlog.md`](../planning/roadmap/09-backlog.md), item
B3). Decide the target user before writing any public copy.

---

## 16. Cost Estimate (EU, monthly, rough)

```text
Azure VM (1× B2ms, 2 vCPU / 8 GiB)        ~$60      (runs the whole Compose stack)
Azure Key Vault                           ~$0–5
Backblaze B2 (blobs + backups + egress)   ~$5–10
Cloudflare (Tunnel + edge, Free/Pro)      $0–20
GHCR (container registry)                 $0
Self-hosted Postgres / Redis / coturn     $0        (on the VM)
Self-hosted observability + GlitchTip     $0        (on the VM — but it is the RAM hog)
------------------------------------------------
Total                                     ~$65–95 / month
```

The observability stack is the reason the VM is 8 GiB rather than 4: Loki,
Tempo, Pyroscope, and GlitchTip together cost more memory than the application.
If memory gets tight, resize to `B4ms` (16 GiB) — a resize, not a rebuild.
Owning Postgres/Redis backups and patching is the trade for the low bill,
mitigated by the nightly encrypted B2 backup and a rehearsed restore drill
([`../operations/runbooks/disaster-recovery.md`](../operations/runbooks/disaster-recovery.md)).

---

## 17. Delivery History

[`../planning/roadmap/README.md`](../planning/roadmap/README.md) is **canonical** — it tracks what is done
and what is left. The short version of how the system got here:

| Phase    | What it delivered                                                                                  |
| -------- | -------------------------------------------------------------------------------------------------- |
| 0        | VM + Terraform, Key Vault + Managed Identity, Cloudflare Tunnel + Caddy, gated CD                  |
| 1        | Tenant + user model with RLS, admin role, audit events                                             |
| 2        | MLS device keys, KeyPackage directory, PRF-sealed keystore                                         |
| 3        | 1:1 encrypted text — ciphertext storage, WS delivery, offline catch-up, receipts                   |
| 4        | Encrypted images — client-side encryption, presigned B2 upload/download                            |
| 5        | The PWA — installable shell, CSP/SRI, service worker, chat UI                                      |
| 6        | Hardening + observability; **the enterprise decommission** (Zitadel, SSO, billing removed)         |
| 7        | GA prep — GDPR, transparency page, retention. Two external paid gates remain: crypto review, pen test |
| B1 / B2  | Group chat; multi-device enrollment                                                                |
| VoIP V1  | 1:1 audio calls, coturn, always-relayed media                                                          |

---

## 18. Future / North-Star

- **Video calls** (V1.1) — the API schema already reserves the widening point
- **Native mobile** (React Native + Expo) — gated on a fail-closed crypto spike:
  [`../planning/mobile/`](../planning/mobile/)
- Group calls (needs an SFU); optional per-tenant compliance mode; multi-region
  / zone-redundant deploy; an Azure sovereign-operator deployment for stricter
  buyers

---

## 19. The One Design Principle

> The server operates the platform; the clients own message privacy.
