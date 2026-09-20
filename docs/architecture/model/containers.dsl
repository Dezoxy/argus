// argus and its containers. Groups are the layers the views colour; the
// security tags mark what the internet can reach and what answers without
// authentication.
//
// Two things are deliberately NOT containers. @argus/contracts and
// @argus/crypto are libraries built into the API and the PWA, not separately
// runnable. And the PWA is a container that runs in the member's browser: in
// production its built dist/ is baked into the ingress image, so nothing
// serves it as its own process.

argus = softwareSystem "Argus" "Invite-only, end-to-end-encrypted messenger, installable as a PWA. The server stores and forwards ciphertext and holds no key that can read a message." {

    group "Edge" {
        cloudflared = container "Cloudflared" "Dials out to Cloudflare and carries tunnelled requests to the ingress. Listens on nothing." "cloudflared" "Layer Edge"
        ingress = container "Ingress" "Single origin: serves the PWA build, routes /api and /ws to the API, host-splits Grafana and GlitchTip, sets CSP and HSTS, and 404s the breakglass path when the Access JWT is absent." "Caddy 2" "Layer Edge,Gateway"
        coturn = container "TURN Relay" "Relays 1:1 call media. The only service with inbound ports open on the VM firewall; every call is relayed, never peer-to-peer, so neither party learns the other's IP." "coturn 4.6, host network" "Layer Edge,Internet-exposed"
    }

    group "Application" {
        webPwa = container "Web PWA" "Runs every cryptographic operation: MLS group state, device keys, attachment encryption, passkey ceremonies. Plaintext and message keys never leave it." "React 19, Vite 8, TypeScript" "Layer App,Web UI"
        api = container "API" "One process serving the REST API and the WebSocket gateway. Routes ciphertext, holds identity, the key directory, friends, calls, admin and GDPR. Never decrypts message content." "NestJS 11, Node 25" "Layer App"
    }

    group "Data" {
        postgres = container "PostgreSQL" "System of record: users, tenants, devices, friends, invites, audit, push subscriptions, and message bodies as ciphertext. Every tenant-scoped table carries tenant_id under FORCE RLS; the app connects as a non-bypass role." "PostgreSQL 16" "Layer Data,Database"
        redis = container "Redis" "Realtime fan-out between WebSocket connections. Persistence is switched off -- it holds no system of record and survives no restart." "Redis 8" "Layer Data,Database"
    }

    group "Maintenance" {
        secretsUnit = container "Secret Fetch Unit" "At boot, reads every secret from Key Vault with the VM Managed Identity and writes it to a private tmpfs as a credential file." "systemd oneshot, bash" "Layer Ops"
        backupTimer = container "Backup Worker" "Nightly: dumps roles and database, encrypts each with age to a public recipient key, uploads to the WORM bucket, then writes a signed success marker." "systemd timer, bash, age" "Layer Ops"
        retentionTimer = container "Retention Workers" "Scheduled pruning: messages past retention, expired attachments and aged audit events." "systemd timers, bash" "Layer Ops"
    }

    group "Observability" {
        prometheus = container "Prometheus" "Scrapes the API, the exporters and coturn; evaluates alert rules; keeps 15 days." "Prometheus 3" "Layer Obs"
        alertmanager = container "Alertmanager" "Routes firing alerts to the webhook receiver." "Alertmanager 0.29" "Layer Obs"
        grafana = container "Grafana" "Dashboards over metrics, logs, traces and profiles. Anonymous access and sign-up are both disabled." "Grafana 12" "Layer Obs"
        loki = container "Loki" "Log store, 7-day retention." "Loki 3.5" "Layer Obs"
        alloy = container "Alloy" "Tails container logs from the host read-only. It is given no Docker socket." "Grafana Alloy" "Layer Obs"
        tempo = container "Tempo" "Trace store, OTLP ingest, 72 hours." "Tempo 2.9" "Layer Obs"
        pyroscope = container "Pyroscope" "Continuous profiles, 72 hours." "Pyroscope 1.13" "Layer Obs"
        glitchtip = container "GlitchTip" "Self-hosted error tracking, with its own worker and its own separate PostgreSQL cluster." "GlitchTip 6.1" "Layer Obs"
        exporters = container "Exporters" "postgres-exporter and redis-exporter, exposing datastore metrics for Prometheus to scrape." "prometheus-community, oliver006" "Layer Obs"
    }
}

// ── Inbound: the only way in ────────────────────────────────────────────────
member -> argus.webPwa "Reads and writes messages in" "Browser" "Person"
tenantAdmin -> argus.webPwa "Administers the tenant in" "Browser" "Person"
cloudflare -> argus.cloudflared "Delivers tunnelled requests to" "Cloudflare Tunnel" "Inbound across trust boundary"
argus.cloudflared -> argus.ingress "Forwards requests to" "HTTP, internal network" "Layer Edge"
argus.ingress -> argus.api "Routes /api and /ws to" "HTTP, WebSocket" "Layer Edge"
argus.ingress -> argus.grafana "Host-routes grafana.* to" "HTTP" "Layer Edge"
argus.ingress -> argus.glitchtip "Host-routes glitchtip.* to" "HTTP" "Layer Edge"

// ── The client ──────────────────────────────────────────────────────────────
argus.webPwa -> argus.ingress "Calls the API and opens the message socket against" "HTTPS, WSS" "Layer App"
argus.webPwa -> b2Attachments "Uploads and downloads encrypted attachments directly against presigned URLs" "HTTPS, S3" "Layer App"
argus.webPwa -> argus.coturn "Relays call media through" "DTLS-SRTP over UDP/TCP" "Layer App"

// ── The API ─────────────────────────────────────────────────────────────────
argus.api -> argus.postgres "Reads and writes ciphertext and metadata in" "PostgreSQL, non-bypass role, tenant set per transaction" "Layer App"
argus.api -> argus.redis "Publishes and subscribes to delivery events on" "Redis pub/sub" "Layer App"
argus.api -> b2Attachments "Mints presigned upload and download URLs for" "S3 SigV4 signing only" "Layer App"
argus.api -> webPush "Sends content-free notifications through" "HTTPS, VAPID" "Layer App"
argus.api -> cloudflareAccess "Verifies breakglass Access tokens against" "JWKS" "Layer App"
argus.api -> argus.tempo "Exports traces to" "OTLP/HTTP" "Layer App"
argus.api -> argus.pyroscope "Pushes profiles to" "HTTP" "Layer App"
argus.api -> argus.glitchtip "Reports exceptions to" "Sentry protocol" "Layer App"

// ── Maintenance ─────────────────────────────────────────────────────────────
argus.secretsUnit -> keyVault "Reads secrets from" "HTTPS, Managed Identity via IMDS" "Layer Ops"
argus.secretsUnit -> argus.api "Provides credential files to" "tmpfs file mount" "Layer Ops"
argus.backupTimer -> argus.postgres "Dumps roles and database from" "pg_dump over the container's local socket" "Layer Ops"
argus.backupTimer -> b2Backups "Uploads age-encrypted dumps to" "HTTPS, S3, write-only key" "Layer Ops"
argus.retentionTimer -> argus.postgres "Prunes expired rows from" "psql over the container's local socket" "Layer Ops"
argus.retentionTimer -> b2Attachments "Deletes expired attachment blobs from" "HTTPS, S3" "Layer Ops"

// ── Observability ───────────────────────────────────────────────────────────
argus.prometheus -> argus.api "Scrapes metrics from" "HTTP, internal only, unauthenticated by design" "Layer Obs"
argus.prometheus -> argus.exporters "Scrapes datastore metrics from" "HTTP" "Layer Obs"
argus.prometheus -> argus.coturn "Scrapes relay metrics from" "HTTP via the host gateway" "Layer Obs"
argus.prometheus -> argus.alertmanager "Sends firing alerts to" "HTTP" "Layer Obs"
argus.alertmanager -> alertReceiver "Posts alert notifications to" "HTTPS webhook" "Layer Obs"
argus.alloy -> argus.loki "Ships container logs to" "HTTP" "Layer Obs"
argus.exporters -> argus.postgres "Reads statistics from" "PostgreSQL, read-only role" "Layer Obs"
argus.exporters -> argus.redis "Reads statistics from" "Redis" "Layer Obs"
argus.grafana -> argus.prometheus "Queries metrics from" "PromQL" "Layer Obs"
argus.grafana -> argus.loki "Queries logs from" "LogQL" "Layer Obs"
argus.grafana -> argus.tempo "Queries traces from" "TraceQL" "Layer Obs"
argus.grafana -> argus.pyroscope "Queries profiles from" "HTTP" "Layer Obs"

// ── Operators reach the gated hostnames ─────────────────────────────────────
opsEngineer -> argus.grafana "Reads dashboards in" "HTTPS, behind Cloudflare Access" "Person"
opsEngineer -> argus.glitchtip "Reads error reports in" "HTTPS, behind Cloudflare Access" "Person"
breakglassOperator -> argus.api "Recovers admin access through" "HTTPS, behind Cloudflare Access" "Person"

// ── Delivery ────────────────────────────────────────────────────────────────
azureControlPlane -> argus.secretsUnit "Runs the deploy script that refreshes" "az vm run-command" "Inbound across trust boundary"
githubActions -> argus.ingress "Publishes the signed image the VM pulls for" "GHCR, cosign-verified"
githubActions -> argus.api "Publishes the signed image the VM pulls for" "GHCR, cosign-verified"
