# argus — Secure Messaging Platform

Privacy-first, end-to-end-encrypted messenger delivered as an installable PWA.
The server is **crypto-blind**: it stores ciphertext + metadata only.

Access is **invite-only** — an admin mints a one-time registration code, you
redeem it and set up a passkey. No email, no password, no external identity
provider.

Architecture:
[`docs/architecture/secure_messaging_platform_plan.md`](docs/architecture/secure_messaging_platform_plan.md).
Phasing & checkpoint status:
[`docs/planning/roadmap/README.md`](docs/planning/roadmap/README.md).

> **Deployment:** the target is a **single Azure VM** (EU, `germanywestcentral`)
> running the stack via **Docker Compose** — self-hosted **Postgres + Redis**
> plus API + PWA + Caddy + cloudflared + **coturn** (TURN relay) and a full
> self-hosted observability stack. Attachment blobs live on **Backblaze B2**
> (S3-compatible, EU `eu-central-003`), DB backups on a separate private EU B2
> bucket, and secrets in **Azure Key Vault** fetched via the VM's **Managed
> Identity** (credential files, never env). Ingress is a **Cloudflare Tunnel** —
> no inbound HTTP ports; the coturn media ports are the sole exception, since a
> tunnel cannot carry UDP. CD runs from GitHub Actions via Azure OIDC through
> the Azure control plane. Kubernetes/AKS was dropped — recover from git history
> if it is ever revisited. Canonical: `AGENTS.md` → _Stack & conventions_.

## What works now

Feature-complete for its v1 scope — the server stays crypto-blind throughout:

- **End-to-end-encrypted messaging** — 1:1 **and group** chat over MLS (RFC
  9420); the server only ever stores and forwards ciphertext + routing metadata.
- **1:1 audio calls** — WebRTC, **always relayed** through self-hosted coturn in
  V1 (peers never learn each other's IP); SDP/ICE travel as MLS ciphertext. **No
  call metadata is stored** — no participants, no timestamps, no duration. Video
  is V1.1.
- **Invite-only identity** — admin-minted registration codes, **passkey-only**
  login, and an immutable, shareable **argus-id**. People are found by exact
  argus-id; there is no browsable directory.
- **Friends list** — the durable contact source that survives a PWA reinstall,
  and the gate on who may start a conversation with you.
- **Multi-device** — verified device linking with proof-of-possession and enrollment fan-out.
- **Encrypted image attachments** — client-side AES-GCM, presigned
  upload/download to Backblaze B2, server-blind.
- **Installable PWA** — manifest + service worker, passkey login gate, live
  send/receive over WebSocket, sealed message-history persistence.
- **Device keystore sealed by the passkey** — WebAuthn **PRF** derives the
  unlock key; **nothing recoverable is stored on the server**, so a lost passkey
  is a fresh start by design. Safety-number (fingerprint) verification guards
  against MITM.
- **Tenant isolation** — PostgreSQL Row-Level Security (FORCE RLS) on every
  tenant-scoped table, verified by a catalog-driven coverage test. The
  deployment itself runs as a single shared tenant pool.
- **Admin & privacy** — metadata-only admin panel (no content path), breakglass
  admin login, GDPR export/erasure, per-user privacy toggles, and a 90-day
  server-side message-retention prune.
- **Self-hosted observability** — Prometheus, Alertmanager, Grafana, Loki,
  Alloy, Tempo, Pyroscope, GlitchTip.

## Repo layout

```text
apps/
  api/                 # NestJS backend — HTTP + WebSocket, crypto-blind routing, identity, key directory,
                       #   friends, calls, admin, GDPR
  web/                 # React + Vite PWA — E2EE chat UI, passkey login, calls, attachments, device linking, admin
packages/
  contracts/           # Shared TypeScript types + Zod schemas (client <-> server envelope)
  crypto/              # MLS (RFC 9420) wrapper — device keys, safety numbers, TURN credential minting
infra/
  azure/terraform/     # Azure VM, NSG, Key Vault, Managed Identity — the production target
  aws/                 # Parallel AWS EC2 experiment (separate tag namespace + kill-switch; not production)
  stack/               # Cloud-agnostic VM runtime: deploy script, Key Vault secret-fetch, Caddy, coturn,
                       #   observability, glitchtip
  backup/ cleanup/     # systemd timers — nightly encrypted DB backup, attachment expiry
  audit-prune/         # systemd timer — audit-event prune
  retention/           # systemd timer — 90-day message prune
  notify/ b2/          # failure alerting, Backblaze bucket CORS
docs/                  # architecture, planning/roadmap, operations, threat models, reviews, GDPR
  architecture/
    model/             # Structurizr C4 model (workspace.dsl + !include fragments)
    overview/          # the Structurizr Documentation tab, and the body of the PDF
    decisions/         # ADRs, adr-tools format, NNNN-short-title.md
scripts/               # repo guards (CSP, dockerignore/secret sync, log labels, PWA build verify)
                       #   + the docs-consistency gate and the architecture PDF builder
.claude/ .agents/      # agent skills (byte-identical mirrors), subagents, hooks, permissions
Makefile               # local stack (up/migrate/api-dev) + architecture (check/docs/view/export/pdf)
.design-sync/          # durable inputs that sync the real UI primitives into the design tool
.github/workflows/     # CI (build/test); security (Semgrep/Checkov/gitleaks/CodeQL/DAST/42Crunch); CD (gated)
compose.yaml           # dev stack (Postgres, Redis, MinIO, api)
compose.prod.yaml      # prod stack (+ Caddy, cloudflared, coturn, observability, glitchtip) — see docs/architecture/deploy.md
```

## Status: feature-complete, production deploy not yet armed

The application is built end-to-end (Phases 0–7, plus group chat, multi-device
sync, and VoIP V1 — see
[`docs/planning/roadmap/README.md`](docs/planning/roadmap/README.md)). What
remains is **operational**, not feature work:

- **The Azure production track is still gated.** The Terraform, the prod Compose
  stack + ingress, the Key Vault secret delivery, and the full build/scan/sign →
  GHCR → VM rollout (migrate-before-serve) all exist as code, but
  **`vars.ENABLE_DEPLOY` is off, so tagged releases do not deploy**.
- **The AWS EC2 experiment box is the environment that actually runs today** —
  its own `aws-v*` tag namespace and `ENABLE_DEPLOY_AWS` kill-switch, 59
  releases to date (latest `aws-v0.8.28`). It carries no real data; it exists to
  prove the stack is portable and to shake out runtime issues before Azure is
  armed. See
  [`docs/operations/runbooks/aws-first-deploy.md`](docs/operations/runbooks/aws-first-deploy.md).
- The two external, paid GA gates — **G4 independent crypto review** and **G5
  pen test** — are still open.

### Local dev

```bash
corepack enable
pnpm install
make up                          # backing services: Postgres, Redis, MinIO
make migrate && make seed        # apply the schema + seed the dev tenant
make api-dev                     # API on http://localhost:3000 (host)
pnpm --filter @argus/web dev     # the PWA on http://localhost:5173
pnpm test
```

Local passkey auth + demo-mode dev flow:
[`docs/operations/local-auth.md`](docs/operations/local-auth.md) ·
[`docs/operations/local-dev.md`](docs/operations/local-dev.md).

### Provision (when you have an Azure subscription)

```bash
cd infra/azure/terraform
cp terraform.tfvars.example terraform.tfvars   # fill in subscription_id, prefix
terraform init
terraform plan
# terraform apply   # creates RG, VNet, NSG, the VM, Key Vault, Managed Identity
```

The VM runs the stack via Docker Compose; secrets are pulled from Key Vault by
its Managed Identity as credential files. Cloudflare (Tunnel + Access) is the
only HTTP ingress — the coturn media ports are the one inbound NSG rule. Deploys
run through GitHub Actions → Azure OIDC → the Azure control plane (no SSH).

## License

Proprietary — © 2026 Dezoxy. All rights reserved. See [LICENSE](LICENSE).
Source-available for reference only; no use, copying, hosting, or redistribution
without written permission.
