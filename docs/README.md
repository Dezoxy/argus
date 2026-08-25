# argus — documentation

Map of the `docs/` tree. Start here.

## Architecture & reference — [`architecture/`](architecture/)

The canonical "how the system is built" docs.

- [`secure_messaging_platform_plan.md`](architecture/secure_messaging_platform_plan.md) — **the architecture**: what exists today (passkey-only invite messenger, MLS, single Azure VM via Docker Compose).
- [`security_toolchain.md`](architecture/security_toolchain.md) — CI gates + local pre-commit + AI-agent guardrails.
- [`deploy.md`](architecture/deploy.md) — production topology (Cloudflare Tunnel → Caddy → api/ws; coturn ingress; Key Vault secrets; migrate-before-serve CD).
- [`mls-library-selection.md`](architecture/mls-library-selection.md) — the `ts-mls` crypto-library decision + spike result.
- [`agent-pipeline.md`](architecture/agent-pipeline.md) · [`agent-portability.md`](architecture/agent-portability.md) — how AI coding agents work this repo.

## Planning & roadmap — [`planning/`](planning/)

What's built, what's left, and the plans for each effort. The canonical phasing lives in
[`planning/roadmap/`](planning/roadmap/) (split per phase, with a progress table and a remaining-work
rollup). See [`planning/README.md`](planning/README.md) for the full plan index.

Plan sets worth knowing about:

- [`planning/improvements/`](planning/improvements/) — codebase-health follow-up tracks (all four shipped).
- [`planning/improvements-2/`](planning/improvements-2/4-files/) — the 2026-06-26 runtime-health plan, born from live AWS-experiment triage.
- [`planning/voip/`](planning/voip/) — the voice/video plan set. **V1 (1:1 audio) has shipped**; video is V1.1.
- [`planning/observability-improvements/`](planning/observability-improvements/) — the post-#325 observability roadmap (A–G, all shipped).
- [`planning/mobile/`](planning/mobile/) — the proposed React Native + Expo native-mobile pivot. **Planning only**, gated on a crypto spike.

## Operations — [`operations/`](operations/)

Running it, locally and in prod.

- [`local-dev.md`](operations/local-dev.md) — the Docker Compose local stack (`make up` / `make migrate` / `make api-dev`).
- [`local-auth.md`](operations/local-auth.md) — passkey-only login + demo-mode dev flow.
- [`load-testing.md`](operations/load-testing.md) — the k6 harness.
- [`runbooks/`](operations/runbooks/) — operational checklists: [first AWS deploy](operations/runbooks/aws-first-deploy.md), [disaster recovery](operations/runbooks/disaster-recovery.md), [migration rollback](operations/runbooks/migration-rollback.md).

## Runbooks (feature-arming) — [`runbooks/`](runbooks/)

Separate from `operations/runbooks/`: one-time arming procedures for individual subsystems —
[GlitchTip](runbooks/arm-glitchtip.md) and [the coturn TURN relay](runbooks/voip-turn.md).

## Security & privacy

- [`threat-models/`](threat-models/) — per-feature security design notes (one per feature; template-driven). Ratify the note before the code. These are **pre-code design records**; shipped status lives in the roadmap.
- [`reviews/`](reviews/) — the security-review campaign (capstone attestation + per-slice evidence) and audit artifacts (e.g. the Lighthouse pass).
- [`gdpr/`](gdpr/) — GDPR Article 30 records, data-residency statement, and the VoIP DPIA.
- [`secrets/`](secrets/) — the secrets and non-secret-config inventories (what lives in Key Vault vs. env).

## Archive — [`archive/`](archive/)

Superseded / historical docs, kept for the record. Do not follow these for current process.
