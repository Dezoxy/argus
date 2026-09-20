# argus — documentation

Map of the `docs/` tree. Start here.

## Architecture — [`architecture/`](architecture/)

**The architecture document.** Start at
[`architecture/README.md`](architecture/README.md): audience reading paths, the
view register and the decision index.

This folder is not a category — it is a document. Everything below its top
level is symlinked into [`architecture/overview/`](architecture/overview/),
which *is* the Structurizr Documentation tab and the body of the PDF. A file
belongs here only if it belongs in that document; `make pdf` renders the lot.

The C4 model lives in [`architecture/model/`](architecture/model/) as text, so
the diagrams cannot drift from their source, and the decision records are in
[`architecture/decisions/`](architecture/decisions/).

## Security — [`security/`](security/)

- [`security/threat-models/`](security/threat-models/) — one note per feature,
  written **before** the code. Pre-code design records; shipped status lives in
  the roadmap.
- [`security/reviews/`](security/reviews/) — the security-review campaign:
  capstone attestation, per-slice evidence, and audit artifacts.

System-level boundaries and controls are in the architecture document
([trust boundaries](architecture/security/trust-boundaries.md),
[security architecture](architecture/security/security-architecture.md)); these
are the per-feature and per-review artifacts behind them.

## Operations — [`operations/`](operations/)

Running it, locally and in production.

- [`local-dev.md`](operations/local-dev.md) — the Docker Compose local stack.
- [`local-auth.md`](operations/local-auth.md) — passkey-only login and the
  demo-mode dev flow.
- [`load-testing.md`](operations/load-testing.md) — the k6 harness.
- [`operations/runbooks/`](operations/runbooks/) — **every runbook**, both
  recovery procedures and one-time feature arming. They used to live in two
  places; they do not any more.

## Planning — [`planning/`](planning/)

What is built, what is left, and the plan for each effort.

- [`planning/phases/`](planning/phases/) — the canonical phasing, split per
  phase with a progress table. Named `phases/` rather than `roadmap/` because
  [`architecture/roadmap/`](architecture/roadmap/roadmap.md) is a different
  thing: that one summarises where the architecture stands, this one is the
  delivery detail behind it.
- See [`planning/README.md`](planning/README.md) for the full plan index.

## Compliance — [`compliance/`](compliance/)

GDPR Article 30 records, the data-residency statement, and the VoIP DPIA.

## Archive — [`archive/`](archive/)

Superseded and historical, kept for the record. **Do not follow these for
current process.**

## Full document index

Every document under `docs/`, so none goes unreachable. `make docs` fails when
a document here is missing — see
[`scripts/check_docs_consistency.py`](../scripts/check_docs_consistency.py).
The sections above are the curated reading paths; this is the complete list.

### Threat models

One note per feature, written before the code.

- [Threat models](security/threat-models/README.md)
- [Threat model: <feature>](security/threat-models/_TEMPLATE.md)
- [Accessibility audit sign-off: WCAG 2.1 AA (#44)](security/threat-models/a11y-audit.md)
- [Threat model — admin (breakglass) access gating via Cloudflare Access](security/threat-models/admin-access-gating.md)
- [Threat model: G3 Admin panel](security/threat-models/admin-panel.md)
- [Threat model: argus-id identity spine](security/threat-models/argus-id-identity.md)
- [Threat model: encrypted attachments](security/threat-models/attachments.md)
- [Threat model: tenant-scoped audit logging](security/threat-models/audit-logging.md)
- [Threat model: API-edge JWT validation + tenant guard](security/threat-models/auth-tenant-context.md)
- [Threat model: B2 attachment-bucket CORS convergence on deploy](security/threat-models/b2-cors-convergence.md)
- [Threat model: billing and plan gating](security/threat-models/billing-plan-gating.md)
- [Threat model: breakglass admin (Phase 3)](security/threat-models/breakglass-admin.md)
- [Threat model: centralized logs (Loki + Alloy — #47b)](security/threat-models/centralized-logs.md)
- [Threat model: code-delivery integrity (SRI + service-worker pinning +
  published bundle hash)](security/threat-models/code-delivery-integrity.md)
- [Threat model: contact-list recovery + tap-to-resume](security/threat-models/contact-list-recovery.md)
- [Threat model — cross-cloud secret fetch (AWS EC2 compute → Azure Key Vault
  via Azure Arc)](security/threat-models/cross-cloud-secret-fetch.md)
- [Threat model: CSPRNG audit (randomness sources)](security/threat-models/csprng-audit.md)
- [Threat model: nightly DB backup (encrypted logical dump → B2)](security/threat-models/db-backup.md)
- [Threat model: delivery receipts (sent / delivered / read)](security/threat-models/delivery-receipts.md)
- [Threat model: client device keystore (IndexedDB)](security/threat-models/device-keystore.md)
- [Threat model: client device provisioning + KeyPackage pool (live client loop,
  Slice 2)](security/threat-models/device-provisioning.md)
- [Threat model — Discovery by argus-id](security/threat-models/discovery-by-argus-id.md)
- [Threat model: encrypted image attachments](security/threat-models/encrypted-attachments.md)
- [Threat model: server-side error tracking (#48)](security/threat-models/error-tracking.md)
- [Threat model: out-of-band fingerprint / safety-number verification
  (checkpoint 20)](security/threat-models/fingerprint-verification.md)
- [Threat model: friend-request realtime delivery + push notification](security/threat-models/friend-request-realtime-push.md)
- [Threat Model: Friendship-Gated Messaging](security/threat-models/friendship-gated-messaging.md)
- [Threat model: frontend observability, PWA caching, and hosting headers](security/threat-models/frontend-observability.md)
- [Threat Model — GDPR Pack (G6)](security/threat-models/gdpr.md)
- [Threat model — Group membership (B1 MLS group chat)](security/threat-models/group-membership.md)
- [Threat model: join a conversation on connect (recipient side, Slice 4)](security/threat-models/join-conversation.md)
- [Threat model: key directory & server key-substitution (MITM)](security/threat-models/key-directory.md)
- [Threat model: the key model (consolidated) — crypto review #1](security/threat-models/key-model.md)
- [Threat model: live messaging (Slice 5)](security/threat-models/live-messaging.md)
- [Threat model: persisted message history (local sealed message log)](security/threat-models/message-history.md)
- [Threat model: message retention & ciphertext pruning](security/threat-models/message-retention.md)
- [Threat model: messaging schema (conversations / members / messages)](security/threat-models/messaging-schema.md)
- [Threat model: metadata exposure (what the crypto-blind server can infer)](security/threat-models/metadata-exposure.md)
- [Threat model: MLS integration (`packages/crypto`)](security/threat-models/mls-integration.md)
- [Threat model: multi-device enrollment (B2)](security/threat-models/multi-device-enrollment.md)
- [Threat model: metrics & observability (checkpoint 47)](security/threat-models/observability.md)
- [Threat model: passkey authentication (Phase 2)](security/threat-models/passkey-auth.md)
- [Threat model: G2 Per-tenant SSO](security/threat-models/per-tenant-sso.md)
- [Threat Model — Phase 5: Frontend Passkey Client](security/threat-models/phase-5-frontend-passkey.md)
- [Threat model — Phase 6: decommission Zitadel/OIDC + the enterprise surface](security/threat-models/phase-6-decommission.md)
- [Threat model — passkey-PRF keystore unlock](security/threat-models/prf-keystore-unlock.md)
- [Threat model: user privacy settings](security/threat-models/privacy-settings.md)
- [Threat model — Profile editing](security/threat-models/profile-edit.md)
- [Threat model: pseudonymous identity (generated handles + avatars)](security/threat-models/pseudonymous-identity.md)
- [Threat model: rate limiting (per-user request throttling)](security/threat-models/rate-limiting.md)
- [Threat model: realtime delivery (WebSocket gateway)](security/threat-models/realtime-delivery.md)
- [Threat model: passkey registration and tenancy (Phase 2)](security/threat-models/registration-and-tenancy.md)
- [Threat model: RLS tenant isolation (Postgres)](security/threat-models/rls-tenant-isolation.md)
- [Threat model: self-minted session tokens (Phase 1)](security/threat-models/session-tokens.md)
- [Threat model: start a 1:1 conversation (initiator side, Slice 3)](security/threat-models/start-conversation.md)
- [Threat model: structured logging & distributed tracing](security/threat-models/structured-logging-and-tracing.md)
- [Threat model: CI container-image supply chain (SUP-1)](security/threat-models/supply-chain-ci.md)
- [Threat model: tenant onboarding (G1)](security/threat-models/tenant-onboarding.md)
- [Threat model: tenant user directory (`GET /users`)](security/threat-models/user-directory.md)
- [Threat model: CD rollout (Slice 4)](security/threat-models/vm-cd.md)
- [Threat model: VM deploy infrastructure (Terraform — slice 1)](security/threat-models/vm-deploy.md)
- [Threat model: production ingress topology (Slice 2)](security/threat-models/vm-ingress.md)
- [Threat model: Key Vault → credential files (Slice 3)](security/threat-models/vm-secrets.md)
- [Threat model: self-hosted Zitadel on the VM (checkpoint 9)](security/threat-models/vm-zitadel.md)
- [Threat model: VoIP 1:1 calling (audio core, V1)](security/threat-models/voip-calling.md)
- [Threat model: POST /calls/turn-credentials](security/threat-models/voip-turn-credentials.md)
- [Threat model: TURN/coturn relay & the first public ingress](security/threat-models/voip-turn.md)
- [Threat model — Web Push notifications (roadmap #40)](security/threat-models/web-push.md)
- [Threat model: MLS Welcome delivery (live client loop)](security/threat-models/welcome-delivery.md)

### Security review campaign

Capstone attestation, per-slice evidence and audit artifacts.

- [00 — Security Review Campaign Attestation](security/reviews/00-attestation.md)
- [Review 01 — Crypto core & key lifecycle](security/reviews/01-crypto-core.md)
- [Review 02 — Server boundary](security/reviews/02-server-boundary.md)
- [Review 03 — Auth, identity & device trust](security/reviews/03-auth-identity.md)
- [Review 04 — Metadata exposure & privacy-at-rest](security/reviews/04-metadata-privacy.md)
- [Review 05 — Client / PWA security](security/reviews/05-client-pwa.md)
- [Slice 6 — Infra, Deploy & Supply Chain (Evidence Note)](security/reviews/06-infra-deploy.md)
- [07 - Live Domain Security Overview](security/reviews/07-live-domain-security-overview.md)
- [Frontend Lighthouse Pass](security/reviews/frontend-lighthouse.md)

### Planning — standalone plans

Plans that are not part of a numbered set.

- [Planning](planning/README.md)
- [Implementation plan: contact list survives a PWA reinstall — via a
  server-backed Friends list](planning/contact-list-recovery-plan.md)
- [Implementation plan: close the controller-layer spec gap (full coverage +
  standing policy)](planning/controller-spec-coverage-plan.md)
- [Frontend Upgrade Implementation Plan (`apps/web`)](planning/frontend-plan.md)
- [Frontend Rebranding Roadmap](planning/frontend-rebranding-roadmap.md)
- [Private-messenger redesign — implementation plan](planning/private-messenger-redesign-plan.md)
- [Security review campaign — prove argus is private & safe](planning/security-review-campaign-plan.md)

### Planning — phases

The canonical phasing, split per phase.

- [Front-load — start now, parallel to Phase 0](planning/phases/00-front-load.md)
- [Phase 0 — Platform foundation (VM + pipeline)](planning/phases/01-phase-0-platform-foundation.md)
- [Phase 1 — Identity & tenancy](planning/phases/02-phase-1-identity-tenancy.md)
- [Phase 2 — Device keys & recovery (crypto foundation)](planning/phases/03-phase-2-device-keys-recovery.md)
- [Phase 3 — 1:1 encrypted text](planning/phases/04-phase-3-1to1-text.md)
- [Phase 4 — Encrypted images](planning/phases/05-phase-4-encrypted-images.md)
- [Phase 5 — Frontend PWA](planning/phases/06-phase-5-frontend-pwa.md)
- [Phase 6 — Hardening & observability](planning/phases/07-phase-6-hardening-observability.md)
- [Phase 7 — GA / go-to-market (the last mile to selling)](planning/phases/08-phase-7-ga.md)
- [Beyond GA — backlog (the deferred hard stuff)](planning/phases/09-backlog.md)
- [argus — Build Roadmap (checkpoints)](planning/phases/README.md)
- [argus — Build Roadmap: detailed history (archived)](planning/phases/history.md)

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

Proposed React Native pivot. Planning only.

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

The 2026-06-26 runtime-health plan.

- [01 - Must fix](planning/improvements-2/4-files/01-must-fix.md)
- [02 - Should improve](planning/improvements-2/4-files/02-should-improve.md)
- [03 - Nice to have](planning/improvements-2/4-files/03-nice-to-have.md)
- [Runtime health improvement plan](planning/improvements-2/4-files/README.md)

### Planning — observability roadmap

Ideas A-G, all shipped.

- [Idea A — Alertmanager receiver + infrastructure alerts](planning/observability-improvements/A-alertmanager-receiver.md)
- [Idea B — Exemplars: click a metric spike → open the trace](planning/observability-improvements/B-exemplars.md)
- [Idea C — Business/domain metrics](planning/observability-improvements/C-business-metrics.md)
- [Idea D — Continuous profiling with Grafana Pyroscope](planning/observability-improvements/D-pyroscope-profiling.md)
- [Idea E — SLO dashboard + multi-burn-rate alerts](planning/observability-improvements/E-slo-dashboard.md)
- [Idea F — Loki alerting rules for security events](planning/observability-improvements/F-loki-security-alerts.md)
- [Idea G — GlitchTip arming runbook + deployment annotations](planning/observability-improvements/G-glitchtip-annotations.md)
- [Observability Improvements — Roadmap](planning/observability-improvements/README.md)

### Operations — runbooks

Every runbook, recovery and feature-arming alike, in one place.

- [First AWS deploy](operations/runbooks/aws-first-deploy.md)
- [Disaster recovery](operations/runbooks/disaster-recovery.md)
- [Migration rollback](operations/runbooks/migration-rollback.md)
- [Arm GlitchTip](operations/runbooks/arm-glitchtip.md)
- [Arm the coturn TURN relay](operations/runbooks/voip-turn.md)

### Operations — local and load

- [Local development stack](operations/local-dev.md)
- [Local passkey auth and demo mode](operations/local-auth.md)
- [Load testing with k6](operations/load-testing.md)

### Compliance

Article 30 records, data residency and the VoIP DPIA.

- [Article 30 Records of Processing Activities](compliance/article-30-records.md)
- [Data Residency Statement](compliance/data-residency.md)
- [DPIA — VoIP 1:1 Calling](compliance/dpia-voip-calling.md)

### Archive

Superseded and historical. **Do not follow these for current process.**

- [docs/archive — historical & superseded docs](archive/README.md)
- [AWS Secure Internal Messaging App — Architecture Plan](archive/aws_secure_internal_messaging_architecture_plan.md)
- [What Fable 5 thinks — multi-hat repo review](archive/fable5-thoughts.md)
