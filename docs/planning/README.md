# Planning

All plan, roadmap, and step-tracking docs for argus. The **canonical phasing**
lives in [`roadmap/`](phases/) (split per phase, with a progress table and a
remaining-work rollup); everything else here is a focused plan for one effort,
each carrying a `**Status:**` header.

Status vocabulary used across these docs: **PROPOSED** → **APPROVED** → (in
progress) → **COMPLETE**, plus **DRAFT** / **REVISED** / **ARCHIVE**. Dates are
ISO (`YYYY-MM-DD`).

> A shipped plan stays here as the **design record** — it explains *why*, and
> the code explains *what*. When the two disagree, the code wins and the plan's
> status header should say so. For the current shape of the system, read
> [`../architecture/secure_messaging_platform_plan.md`](../architecture/secure_messaging_platform_plan.md).

## The build roadmap

- [`roadmap/`](phases/) — the living checkpoint checklist, split by phase. Start at
  [`roadmap/README.md`](phases/README.md) for the progress table and what's left.
- [`roadmap/history.md`](phases/history.md) — the archived per-checkpoint build log (PR-by-PR, snapshot
  2026-06-14). New status goes in the phase files, not here.

## Focused plans

| Plan                                                                     | Scope                                              | Status                             |
| ------------------------------------------------------------------------ | -------------------------------------------------- | ---------------------------------- |
| [frontend-plan.md](frontend-plan.md)                                     | 14-step `apps/web` rebuild + F1–F6 (roadmap #44a)  | COMPLETE (PRs #87–#146)            |
| [private-messenger-redesign-plan.md](private-messenger-redesign-plan.md) | Product pivot: enterprise OIDC → passkey messenger | **IMPLEMENTED** (migrations 0030–0039) |
| [contact-list-recovery-plan.md](contact-list-recovery-plan.md)           | Server-backed Friends list + tap-to-resume         | **COMPLETE** (friendships `0042`, PRs #234–#238 + follow-ups) |
| [frontend-rebranding-roadmap.md](frontend-rebranding-roadmap.md)         | "Minimal Messenger OS" UI/UX rebrand               | in progress (v2 sketches live at `/v2`) |
| [controller-spec-coverage-plan.md](controller-spec-coverage-plan.md)     | Close the controller-spec gap (3 slices)           | APPROVED (not started)             |
| [security-review-campaign-plan.md](security-review-campaign-plan.md)     | 6-slice adversarial review → evidence notes        | done (see [`../reviews/`](../security/reviews/)) |

## Codebase improvement tracks

- [`improvements/`](improvements/) — the 2026-06-21 codebase-health follow-ups (messaging-service refactor,
  RLS test coverage, ops hardening, message retention). **All four tracks shipped.**
- [`improvements-2/4-files/`](improvements-2/4-files/) — the 2026-06-26
  **runtime**-health plan, born from live AWS-experiment triage (stale Friends
  state, false critical alerts, broken log labels). Must-fix and should-improve
  items are merged; deployed verification is the remaining column.

## Feature plans

- [`voip/`](voip/) — 1:1 end-to-end-encrypted **voice calling** (WebRTC P2P +
  self-hosted coturn, relay-only, PWA). 12-file set, consilium-reviewed.
  **Status: V1 SHIPPED (audio-only)** — PRs #450–#453; video and the direct-P2P
  opt-out are V1.1. Start at [`voip/README.md`](voip/README.md).
- [`observability-improvements/`](observability-improvements/) — the post-#325
  observability roadmap (Alertmanager, exemplars, business metrics, Pyroscope,
  SLO dashboard, Loki security alerts, GlitchTip). **All seven ideas shipped.**
- [`mobile/`](mobile/) — the proposed **React Native + Expo** native-mobile
  pivot, driven by the iOS PWA's inability to ring a locked phone. **Status:
  planning only** — the whole commitment is gated on a fail-closed Phase-0 spike
  proving the MLS engine's X25519 key exchange works without a browser crypto
  API.
