# argus — documentation

Map of the `docs/` tree. Start here.

## Architecture & reference — [`architecture/`](architecture/)

The canonical "how the system is built" docs.

- [`secure_messaging_platform_plan.md`](architecture/secure_messaging_platform_plan.md)
  — **the architecture**: what exists today (passkey-only invite messenger, MLS,
  single Azure VM via Docker Compose).
- [`security_toolchain.md`](architecture/security_toolchain.md) — CI gates + local pre-commit + AI-agent guardrails.
- [`deploy.md`](architecture/deploy.md) — production topology (Cloudflare Tunnel
  → Caddy → api/ws; coturn ingress; Key Vault secrets; migrate-before-serve CD).
- [`mls-library-selection.md`](architecture/mls-library-selection.md) — the `ts-mls` crypto-library decision + spike result.
- [`agent-pipeline.md`](architecture/agent-pipeline.md) ·
  [`agent-portability.md`](architecture/agent-portability.md) — how AI coding
  agents work this repo.

## Planning & roadmap — [`planning/`](planning/)

What's built, what's left, and the plans for each effort. The canonical phasing lives in
[`planning/roadmap/`](planning/roadmap/) (split per phase, with a progress table and a remaining-work
rollup). See [`planning/README.md`](planning/README.md) for the full plan index.

Plan sets worth knowing about:

- [`planning/improvements/`](planning/improvements/) — codebase-health follow-up tracks (all four shipped).
- [`planning/improvements-2/`](planning/improvements-2/4-files/) — the 2026-06-26 runtime-health plan, born from live AWS-experiment triage.
- [`planning/voip/`](planning/voip/) — the voice/video plan set. **V1 (1:1 audio) has shipped**; video is V1.1.
- [`planning/observability-improvements/`](planning/observability-improvements/) — the post-#325 observability roadmap (A–G, all shipped).
- [`planning/mobile/`](planning/mobile/) — the proposed React Native + Expo
  native-mobile pivot. **Planning only**, gated on a crypto spike.

## Operations — [`operations/`](operations/)

Running it, locally and in prod.

- [`local-dev.md`](operations/local-dev.md) — the Docker Compose local stack
  (`make up` / `make migrate` / `make api-dev`).
- [`local-auth.md`](operations/local-auth.md) — passkey-only login + demo-mode dev flow.
- [`load-testing.md`](operations/load-testing.md) — the k6 harness.
- [`runbooks/`](operations/runbooks/) — operational checklists: [first AWS
  deploy](operations/runbooks/aws-first-deploy.md), [disaster
  recovery](operations/runbooks/disaster-recovery.md), [migration
  rollback](operations/runbooks/migration-rollback.md).

## Runbooks (feature-arming) — [`runbooks/`](runbooks/)

Separate from `operations/runbooks/`: one-time arming procedures for individual subsystems —
[GlitchTip](runbooks/arm-glitchtip.md) and [the coturn TURN relay](runbooks/voip-turn.md).

## Security & privacy

- [`threat-models/`](threat-models/) — per-feature security design notes (one
  per feature; template-driven). Ratify the note before the code. These are
  **pre-code design records**; shipped status lives in the roadmap.
- [`reviews/`](reviews/) — the security-review campaign (capstone attestation +
  per-slice evidence) and audit artifacts (e.g. the Lighthouse pass).
- [`gdpr/`](gdpr/) — GDPR Article 30 records, data-residency statement, and the VoIP DPIA.
- [`secrets/`](secrets/) — the secrets and non-secret-config inventories (what
  lives in Key Vault vs. env).

## Archive — [`archive/`](archive/)

Superseded / historical docs, kept for the record. Do not follow these for
current process.

## Full document index

Every document under `docs/`, so none goes unreachable. `make docs` fails when
a document here is missing — see
[`scripts/check_docs_consistency.py`](../scripts/check_docs_consistency.py).
The sections above are the curated reading paths; this is the complete list.

### Threat models

One note per feature, written before the code. These are pre-code design
records; shipped status lives in the roadmap.

- [Threat models](threat-models/README.md)
- [Threat model: <feature>](threat-models/_TEMPLATE.md)
- [Accessibility audit sign-off: WCAG 2.1 AA (#44)](threat-models/a11y-audit.md)
- [Threat model — admin (breakglass) access gating via Cloudflare Access](threat-models/admin-access-gating.md)
- [Threat model: G3 Admin panel](threat-models/admin-panel.md)
- [Threat model: argus-id identity spine](threat-models/argus-id-identity.md)
- [Threat model: encrypted attachments](threat-models/attachments.md)
- [Threat model: tenant-scoped audit logging](threat-models/audit-logging.md)
- [Threat model: API-edge JWT validation + tenant guard](threat-models/auth-tenant-context.md)
- [Threat model: B2 attachment-bucket CORS convergence on deploy](threat-models/b2-cors-convergence.md)
- [Threat model: billing and plan gating](threat-models/billing-plan-gating.md)
- [Threat model: breakglass admin (Phase 3)](threat-models/breakglass-admin.md)
- [Threat model: centralized logs (Loki + Alloy — #47b)](threat-models/centralized-logs.md)
- [Threat model: code-delivery integrity (SRI + service-worker pinning +
  published bundle hash)](threat-models/code-delivery-integrity.md)
- [Threat model: contact-list recovery + tap-to-resume](threat-models/contact-list-recovery.md)
- [Threat model — cross-cloud secret fetch (AWS EC2 compute → Azure Key Vault
  via Azure Arc)](threat-models/cross-cloud-secret-fetch.md)
- [Threat model: CSPRNG audit (randomness sources)](threat-models/csprng-audit.md)
- [Threat model: nightly DB backup (encrypted logical dump → B2)](threat-models/db-backup.md)
- [Threat model: delivery receipts (sent / delivered / read)](threat-models/delivery-receipts.md)
- [Threat model: client device keystore (IndexedDB)](threat-models/device-keystore.md)
- [Threat model: client device provisioning + KeyPackage pool (live client loop,
  Slice 2)](threat-models/device-provisioning.md)
- [Threat model — Discovery by argus-id](threat-models/discovery-by-argus-id.md)
- [Threat model: encrypted image attachments](threat-models/encrypted-attachments.md)
- [Threat model: server-side error tracking (#48)](threat-models/error-tracking.md)
- [Threat model: out-of-band fingerprint / safety-number verification
  (checkpoint 20)](threat-models/fingerprint-verification.md)
- [Threat model: friend-request realtime delivery + push notification](threat-models/friend-request-realtime-push.md)
- [Threat Model: Friendship-Gated Messaging](threat-models/friendship-gated-messaging.md)
- [Threat model: frontend observability, PWA caching, and hosting headers](threat-models/frontend-observability.md)
- [Threat Model — GDPR Pack (G6)](threat-models/gdpr.md)
- [Threat model — Group membership (B1 MLS group chat)](threat-models/group-membership.md)
- [Threat model: join a conversation on connect (recipient side, Slice 4)](threat-models/join-conversation.md)
- [Threat model: key directory & server key-substitution (MITM)](threat-models/key-directory.md)
- [Threat model: the key model (consolidated) — crypto review #1](threat-models/key-model.md)
- [Threat model: live messaging (Slice 5)](threat-models/live-messaging.md)
- [Threat model: persisted message history (local sealed message log)](threat-models/message-history.md)
- [Threat model: message retention & ciphertext pruning](threat-models/message-retention.md)
- [Threat model: messaging schema (conversations / members / messages)](threat-models/messaging-schema.md)
- [Threat model: metadata exposure (what the crypto-blind server can infer)](threat-models/metadata-exposure.md)
- [Threat model: MLS integration (`packages/crypto`)](threat-models/mls-integration.md)
- [Threat model: multi-device enrollment (B2)](threat-models/multi-device-enrollment.md)
- [Threat model: metrics & observability (checkpoint 47)](threat-models/observability.md)
- [Threat model: passkey authentication (Phase 2)](threat-models/passkey-auth.md)
- [Threat model: G2 Per-tenant SSO](threat-models/per-tenant-sso.md)
- [Threat Model — Phase 5: Frontend Passkey Client](threat-models/phase-5-frontend-passkey.md)
- [Threat model — Phase 6: decommission Zitadel/OIDC + the enterprise surface](threat-models/phase-6-decommission.md)
- [Threat model — passkey-PRF keystore unlock](threat-models/prf-keystore-unlock.md)
- [Threat model: user privacy settings](threat-models/privacy-settings.md)
- [Threat model — Profile editing](threat-models/profile-edit.md)
- [Threat model: pseudonymous identity (generated handles + avatars)](threat-models/pseudonymous-identity.md)
- [Threat model: rate limiting (per-user request throttling)](threat-models/rate-limiting.md)
- [Threat model: realtime delivery (WebSocket gateway)](threat-models/realtime-delivery.md)
- [Threat model: passkey registration and tenancy (Phase 2)](threat-models/registration-and-tenancy.md)
- [Threat model: RLS tenant isolation (Postgres)](threat-models/rls-tenant-isolation.md)
- [Threat model: self-minted session tokens (Phase 1)](threat-models/session-tokens.md)
- [Threat model: start a 1:1 conversation (initiator side, Slice 3)](threat-models/start-conversation.md)
- [Threat model: structured logging & distributed tracing](threat-models/structured-logging-and-tracing.md)
- [Threat model: CI container-image supply chain (SUP-1)](threat-models/supply-chain-ci.md)
- [Threat model: tenant onboarding (G1)](threat-models/tenant-onboarding.md)
- [Threat model: tenant user directory (`GET /users`)](threat-models/user-directory.md)
- [Threat model: CD rollout (Slice 4)](threat-models/vm-cd.md)
- [Threat model: VM deploy infrastructure (Terraform — slice 1)](threat-models/vm-deploy.md)
- [Threat model: production ingress topology (Slice 2)](threat-models/vm-ingress.md)
- [Threat model: Key Vault → credential files (Slice 3)](threat-models/vm-secrets.md)
- [Threat model: self-hosted Zitadel on the VM (checkpoint 9)](threat-models/vm-zitadel.md)
- [Threat model: VoIP 1:1 calling (audio core, V1)](threat-models/voip-calling.md)
- [Threat model: POST /calls/turn-credentials](threat-models/voip-turn-credentials.md)
- [Threat model: TURN/coturn relay & the first public ingress](threat-models/voip-turn.md)
- [Threat model — Web Push notifications (roadmap #40)](threat-models/web-push.md)
- [Threat model: MLS Welcome delivery (live client loop)](threat-models/welcome-delivery.md)

### Planning — standalone plans

Plans that are not part of a numbered set.

- [Implementation plan: contact list survives a PWA reinstall — via a
  server-backed Friends list](planning/contact-list-recovery-plan.md)
- [Implementation plan: close the controller-layer spec gap (full coverage +
  standing policy)](planning/controller-spec-coverage-plan.md)
- [Frontend Upgrade Implementation Plan (`apps/web`)](planning/frontend-plan.md)
- [Frontend Rebranding Roadmap](planning/frontend-rebranding-roadmap.md)
- [Private-messenger redesign — implementation plan](planning/private-messenger-redesign-plan.md)
- [Security review campaign — prove argus is private & safe](planning/security-review-campaign-plan.md)

### Planning — roadmap

The canonical phasing, split per phase.

- [Front-load — start now, parallel to Phase 0](planning/roadmap/00-front-load.md)
- [Phase 0 — Platform foundation (VM + pipeline)](planning/roadmap/01-phase-0-platform-foundation.md)
- [Phase 1 — Identity & tenancy](planning/roadmap/02-phase-1-identity-tenancy.md)
- [Phase 2 — Device keys & recovery (crypto foundation)](planning/roadmap/03-phase-2-device-keys-recovery.md)
- [Phase 3 — 1:1 encrypted text](planning/roadmap/04-phase-3-1to1-text.md)
- [Phase 4 — Encrypted images](planning/roadmap/05-phase-4-encrypted-images.md)
- [Phase 5 — Frontend PWA](planning/roadmap/06-phase-5-frontend-pwa.md)
- [Phase 6 — Hardening & observability](planning/roadmap/07-phase-6-hardening-observability.md)
- [Phase 7 — GA / go-to-market (the last mile to selling)](planning/roadmap/08-phase-7-ga.md)
- [Beyond GA — backlog (the deferred hard stuff)](planning/roadmap/09-backlog.md)
- [argus — Build Roadmap (checkpoints)](planning/roadmap/README.md)
- [argus — Build Roadmap: detailed history (archived)](planning/roadmap/history.md)

### Planning — voice and video

V1 (1:1 audio) has shipped; video is V1.1.

- [00 — VoIP Overview & Goals](planning/voip/00-overview-and-goals.md)
- [01 — Architecture & E2EE Crypto Model](planning/voip/01-architecture-and-crypto-model.md)
- [Call Signaling Protocol & State Machine](planning/voip/02-signaling-protocol-and-state-machine.md)
- [Infrastructure: TURN/coturn & Networking](planning/voip/03-infrastructure-turn-and-networking.md)
- [04 — Server API & Database](planning/voip/04-server-api-and-database.md)
- [05 — Frontend PWA & WebRTC client](planning/voip/05-frontend-pwa-and-webrtc.md)
- [06 — Threat Model & Privacy (argus VoIP)](planning/voip/06-threat-model-and-privacy.md)
- [07 — Comparative Survey: How Mature Systems Do E2EE Calling](planning/voip/07-comparative-survey.md)
- [08 — Roadmap & Delivery Slices](planning/voip/08-roadmap-and-delivery-slices.md)
- [09 — Decision Log & Open Questions](planning/voip/09-decision-log-and-open-questions.md)
- [CONSILIUM.md — argus VoIP Plan Review](planning/voip/CONSILIUM.md)
- [argus VoIP — Implementation Plan](planning/voip/README.md)

### Planning — native mobile

Proposed React Native + Expo pivot. Planning only, gated on a crypto spike.

- [00 — Overview & decision](planning/mobile/00-overview-and-decision.md)
- [01 — Code reuse & monorepo wiring](planning/mobile/01-code-reuse-and-monorepo.md)
- [02 — Phase-0 spike (the fail-closed gate)](planning/mobile/02-phase-0-spike.md)
- [03 — Roadmap (iOS first, then Android)](planning/mobile/03-roadmap-ios-then-android.md)
- [04 — Security & threat model](planning/mobile/04-security-and-threat-model.md)
- [Mobile pivot — native iOS + Android (React Native + Expo)](planning/mobile/README.md)

### Planning — codebase-health tracks

All four shipped.

- [Track 1 — Split the messaging service (structural refactor, zero behavior change)](planning/improvements/01-messaging-service-refactor.md)
- [Track 2 — Close API spec gaps + make RLS coverage exhaustive](planning/improvements/02-test-coverage-and-rls-assertions.md)
- [Track 3 — Operational / infra hardening](planning/improvements/03-ops-infra-hardening.md)
- [Track 4 — Message retention & ciphertext pruning (bound DB growth)](planning/improvements/04-message-retention-and-pruning.md)
- [Codebase improvement tracks](planning/improvements/README.md)

### Planning — runtime-health tracks

The 2026-06-26 plan, born from live AWS-experiment triage.

- [01 - Must fix](planning/improvements-2/4-files/01-must-fix.md)
- [02 - Should improve](planning/improvements-2/4-files/02-should-improve.md)
- [03 - Nice to have](planning/improvements-2/4-files/03-nice-to-have.md)
- [Runtime health improvement plan](planning/improvements-2/4-files/README.md)

### Planning — observability roadmap

Ideas A–G, all shipped.

- [Idea A — Alertmanager receiver + infrastructure alerts](planning/observability-improvements/A-alertmanager-receiver.md)
- [Idea B — Exemplars: click a metric spike → open the trace](planning/observability-improvements/B-exemplars.md)
- [Idea C — Business/domain metrics](planning/observability-improvements/C-business-metrics.md)
- [Idea D — Continuous profiling with Grafana Pyroscope](planning/observability-improvements/D-pyroscope-profiling.md)
- [Idea E — SLO dashboard + multi-burn-rate alerts](planning/observability-improvements/E-slo-dashboard.md)
- [Idea F — Loki alerting rules for security events](planning/observability-improvements/F-loki-security-alerts.md)
- [Idea G — GlitchTip arming runbook + deployment annotations](planning/observability-improvements/G-glitchtip-annotations.md)
- [Observability Improvements — Roadmap](planning/observability-improvements/README.md)

### Security review campaign

Capstone attestation plus per-slice evidence, and audit artifacts.

- [00 — Security Review Campaign Attestation](reviews/00-attestation.md)
- [Review 01 — Crypto core & key lifecycle](reviews/01-crypto-core.md)
- [Review 02 — Server boundary](reviews/02-server-boundary.md)
- [Review 03 — Auth, identity & device trust](reviews/03-auth-identity.md)
- [Review 04 — Metadata exposure & privacy-at-rest](reviews/04-metadata-privacy.md)
- [Review 05 — Client / PWA security](reviews/05-client-pwa.md)
- [Slice 6 — Infra, Deploy & Supply Chain (Evidence Note)](reviews/06-infra-deploy.md)
- [07 - Live Domain Security Overview](reviews/07-live-domain-security-overview.md)
- [Frontend Lighthouse Pass](reviews/frontend-lighthouse.md)

### GDPR

Article 30 records, the data-residency statement, and the VoIP DPIA.

- [Article 30 Records of Processing Activities](gdpr/article-30-records.md)
- [Data Residency Statement](gdpr/data-residency.md)
- [DPIA — VoIP 1:1 Calling](gdpr/dpia-voip-calling.md)

### Secrets and configuration inventories

What lives in Key Vault versus what is ordinary config.

- [Configuration inventory (non-secret)](secrets/config-inventory.md)
- [Secrets inventory](secrets/secrets-inventory.md)

### Archive

Superseded and historical. **Do not follow these for current process.**

- [docs/archive — historical & superseded docs](archive/README.md)
- [AWS Secure Internal Messaging App — Architecture Plan](archive/aws_secure_internal_messaging_architecture_plan.md)
- [What Fable 5 thinks — multi-hat repo review](archive/fable5-thoughts.md)
