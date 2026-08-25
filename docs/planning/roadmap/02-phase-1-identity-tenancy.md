# Phase 1 — Identity & tenancy

> Part of the [build roadmap](README.md). Legend: `[ ]` todo · `[~]` in progress · `[x]` done · 🔒 security-gated.

**Progress:** 8/8 resolved (#9 closed as superseded).

> Goal: real login, real tenant isolation enforced by the database.

- [x] 9. ~~**Zitadel deployed** (Docker Compose on the VM) with its DB — admin console reachable~~ — **SUPERSEDED / N/A.** Zitadel was decommissioned in Phase 6 (`0039_decommission_enterprise.sql`; `threat-models/phase-6-decommission.md`). Auth is passkey-only and the API mints its own EdDSA session tokens — there is no IdP to deploy. Nothing here awaits arming.
- [x] 10. ~~**Managed Postgres** (Flexible Server) + private endpoint~~ 🔒 — **SUPERSEDED / N/A** (the VM self-hosts Postgres under FORCE-RLS; see #11/#12).
- [x] 11. **Drizzle wired** with a per-transaction `app.tenant_id` session var
- [x] 12. **`tenants` + `users` with RLS** — cross-tenant read provably blocked by a test 🔒
- [x] 13. ~~**OIDC login** via Zitadel works; API validates JWTs~~ — **SUPERSEDED** by passkey (WebAuthn) login + API-minted EdDSA tokens (Phase 6).
- [x] 14. **Tenant guard** sets `app.tenant_id` from the verified token only (never client input) 🔒
- [x] 15. **`/me`** — Zod-validated, documented in the spec. _(The browsable **user directory** was removed in the redesign; discovery is exact-argus-id lookup only.)_
- [x] 16. **Audit events** table + login/logout auditing (IDs/metadata only, no secrets) 🔒
