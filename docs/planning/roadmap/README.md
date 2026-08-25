# argus — Build Roadmap (checkpoints)

Living checklist, split by phase. Check items off as they land. Each checkpoint states its **done-when** so "complete" is objective. **Effort is per-item, not flat** — most are ~½–2 days, but a few (notably #41 core UX, #42, #43) are _weeks_; don't plan runway against an average. The implied "~10–12 weeks" is realistically **6–9 months solo**.

> **Detailed build log:** per-checkpoint implementation notes and PR-by-PR history live in [`history.md`](history.md). This folder is the slim status checklist.

Legend: `[ ]` todo · `[~]` in progress · `[x]` done · 🔒 security-gated (route through the matching reviewer).

**Status (2026-07):** **feature-complete.** Phases 0–7 are built, plus group chat (B1), multi-device sync (B2), and **VoIP V1** (1:1 audio calls — outside the original numbering; see [`../voip/`](../voip/)). The server stays crypto-blind; tenant isolation is FORCE-RLS, now guarded by a catalog-driven coverage test. Since the 2026-06 snapshot the product also **pivoted to an invite-only, passkey-only messenger** — Zitadel/OIDC, per-tenant SSO, billing, and the browsable directory were decommissioned in Phase 6 (`0039`), so several Phase-1 items are closed as *superseded* rather than delivered.

**What remains is operational, not feature work:** the one-time **Azure arming** of the gated deploy track (`vars.ENABLE_DEPLOY` is off, so tagged releases don't deploy) flips the live half of the Phase-0/6 `[~]` items, and the two external paid GA gates — **G4 crypto review**, **G5 pen test** — stay open. A handful of `[~]` residuals (the S1 iOS-PWA proof, #39/#41 polish) are noted inline in the phase files. The stack *does* run today on the parallel **AWS EC2 experiment box** (`aws-v*` tags) — no real data, but it is where runtime issues surface.

## Progress by phase

| Phase                                                            | Items | Done | Status                                       |
| --------------------------------------------------------------- | ----- | ---- | ------------------------------------------- |
| [Front-load](00-front-load.md)                                  | 2     | 0    | spikes in flight                            |
| [Phase 0 — Platform foundation](01-phase-0-platform-foundation.md) | 10    | 0    | code-complete + gated; awaits Azure arming  |
| [Phase 1 — Identity & tenancy](02-phase-1-identity-tenancy.md)  | 8     | 8    | done (#9/#13 superseded — no IdP)           |
| [Phase 2 — Device keys & recovery](03-phase-2-device-keys-recovery.md) | 9 | 9    | done                                        |
| [Phase 3 — 1:1 encrypted text](04-phase-3-1to1-text.md)        | 9     | 9    | done                                        |
| [Phase 4 — Encrypted images](05-phase-4-encrypted-images.md)   | 6     | 6    | done                                        |
| [Phase 5 — Frontend PWA](06-phase-5-frontend-pwa.md)           | 9     | 7    | #39/#41 polish residual                     |
| [Phase 6 — Hardening & observability](07-phase-6-hardening-observability.md) | 7 | 2 | observability + #50 resilience docs built; deploy/at-scale at arming |
| [Phase 7 — GA / go-to-market](08-phase-7-ga.md)               | 8     | 6    | G4/G5 external paid gates open              |
| [Backlog — beyond GA](09-backlog.md)                          | 5     | 2    | deferred hard stuff                         |
| **Total**                                                       | **73**| **49** |                                           |

## Remaining work (everything not `[x]`)

Open items, grouped by what unblocks them.

**Gated on the one-time Azure arming** (code-complete, flips on provisioning):

- Phase 0: #1, #2, #3, #4, #5, #6, #7, #7a, #8, #8a
- Phase 6: #45, #47, #47b, #49, #50 (at-scale load run + live restore drill — the DR runbook + k6 harness are already built)

**External, paid (schedule early):**

- Front-load: S2 (book G4/G5)
- Phase 7: G4 (crypto review), G5 (pen test)

**Product polish / proofs (USER):**

- Front-load: S1 (RFC 9420 interop vectors, bundle-size, iOS-PWA proof)
- Phase 5: #39 (iOS installed-PWA proof), #41 (core-UX polish)

**Backlog (deferred by design):** B3 (compliance mode), B4 (multi-region), B5 (SOC 2 / ISO 27001 / NIS2).

## Reality notes

- Checkpoints **17–32 (crypto + messaging) are the hard, high-risk core** — most of the effort and all of the "is this actually secure" risk lives there. Don't rush them.
- Two GA gates (**G4 crypto review, G5 pen test**) are **external and paid** — schedule and budget them early; they block launch.
- This is a genuine multi-month solo effort. That's expected — the list just makes it honest.
- **Front-load the unknowns** (spikes S1–S2): the hardest thing (MLS) and the longest-lead-time thing (paid audits) start _now_, not in sequence.
- This roadmap is **canonical** for phasing. `docs/architecture/secure_messaging_platform_plan.md` describes the system's *shape*, not its sequencing, and defers to this folder — its §17 is only a one-line-per-phase recap.
- **Work that landed outside this numbering:** VoIP V1 ([`../voip/`](../voip/)), the friends list ([`../contact-list-recovery-plan.md`](../contact-list-recovery-plan.md)), the private-messenger pivot ([`../private-messenger-redesign-plan.md`](../private-messenger-redesign-plan.md)), and the codebase-health tracks ([`../improvements/`](../improvements/)). The 73-item table below predates all of them.
- Each phase is gated by its `docs/threat-models/*.md` note (rls-tenant-isolation, key-directory, prf-keystore-unlock, attachments) — ratify the note before the code.
