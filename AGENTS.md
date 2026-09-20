# AGENTS.md — argus engineering contract

Canonical instructions for **any** AI coding agent working in this repo (Codex,
Claude Code, Cursor, Gemini CLI, …). Tool-specific wiring is at the bottom; the
rules here apply to all.

Privacy-first, **end-to-end-encrypted** messenger, installable as a PWA.
**Invite-only** (admin-minted registration code → passkey) and **passkey-only**
thereafter. The multi-tenant machinery (`tenant_id` + FORCE RLS) is fully
enforced, but the deployment runs as **one shared tenant pool** — privacy comes
from argus-id-only discovery + E2EE, not tenant walls. Architecture:
`docs/architecture/secure_messaging_platform_plan.md`. Security toolchain:
`docs/architecture/security_toolchain.md`.

## Languages

- **All application code is TypeScript** (strict, ESM): React + Vite PWA, NestJS
  API, WebSocket gateway, workers, and the shared `@argus/contracts` (Zod)
  package.
- **Crypto**: a TypeScript wrapper over an MLS (WASM) library in
  `packages/crypto`. You do not write raw crypto.
- **Data**: SQL (PostgreSQL). **Infra/glue**: Terraform (HCL), Docker Compose /
  CI (YAML), Bash, Dockerfile, Make. (Kubernetes was dropped; deploy is a single
  VM via Docker Compose — see Stack & conventions.)

## Non-negotiable security invariants

Hard rules. A change that violates one is wrong even if it "works".

1. **The server is crypto-blind.** It stores and forwards ciphertext only. Never
   decrypt, inspect, or derive meaning from message content on the server.
2. **Never log or persist** plaintext content, private/session/message keys,
   passphrases, auth tokens, full `Authorization` headers, or presigned URLs.
   Logs carry IDs and metadata only.
3. **Every tenant-scoped table has `tenant_id` + an enforced RLS policy.** No
   cross-tenant reads. A new table without RLS is a block.
4. **No hand-rolled crypto.** All cryptography goes through the MLS library in
   `packages/crypto`. Primitives must not appear elsewhere.
5. **Secrets come from Key Vault via Managed Identity.** Never commit secrets;
   never put long-lived cloud creds in env files — deliver them as
   runtime-fetched values or mounted credential **files** (e.g. systemd
   `LoadCredential`, populated from Key Vault by the VM's Managed Identity). A
   non-secret config value (e.g. an S3 access-key-**id**, which rides in every
   presigned URL) may use env; the matching secret may not.
6. **No admin path to content.** Admin/ops surfaces expose metadata only — never
   message text or images.

## Stack & conventions

- TypeScript strict, ESM. Monorepo via pnpm workspaces (`apps/*`, `packages/*`).
- Backend **NestJS** (`apps/api`); realtime WebSocket gateway; **PostgreSQL** +
  RLS; DB layer SQL-first (Drizzle/Kysely, not Prisma) so the tenant session var
  is set per transaction.
- Shared client↔server types + **Zod** schemas live in `@argus/contracts`.
  Validate at every boundary.
- Frontend **React + Vite** PWA. Deploy: a **single Azure VM** (EU) running the
  stack via **Docker Compose** — **self-hosted Postgres + Redis** (auth is
  passkey-only; Zitadel/OIDC was decommissioned in Phase 6); attachment blobs on
  **Backblaze B2** (S3-compatible, EU `eu-central-003`); DB backups to a
  separate private EU B2 bucket. **1:1 audio calls** run over WebRTC, always
  relayed through self-hosted **coturn**; a full self-hosted **observability
  stack** (Prometheus/Alertmanager/Grafana/Loki/Alloy/Tempo/Pyroscope/GlitchTip)
  runs on the same VM. Ingress via **Cloudflare Tunnel** (no inbound HTTP ports
  — the coturn media ports are the sole exception, since a tunnel cannot carry
  UDP); CD via **`az vm run-command`** (Azure control plane, GitHub OIDC).
  Secrets in **Azure Key Vault**, fetched on the VM via **Managed Identity**
  (delivered as credential files, never env). IaC Terraform is split by concern:
  Azure provisioning in `infra/azure/terraform/`, the cloud-agnostic runtime the
  VM runs (deploy script, secret-fetch, Caddy, observability, glitchtip) in
  `infra/stack/`, and a parallel AWS experiment in `infra/aws/`. (Kubernetes/AKS
  was dropped — the old AKS/Helm/Argo CD scaffolds were removed; recover from
  git history if K8s is ever revisited.)

## Definition of done

- `pnpm -r typecheck && pnpm -r test && pnpm lint && pnpm format:check` pass.
- User-visible web change: Playwright E2E suite passes (`pnpm --filter
  @argus/web test:e2e`); new user-facing flows get an E2E test; **removed or
  renamed UI interactions must have their E2E assertions updated in the same
  commit** — grep `apps/web/e2e/` for the changed label/text/role before
  pushing. The `e2e` CI job gates merges on this.
- New API endpoints: in the OpenAPI spec with auth + typed schemas (refresh the
  spec, run the 42Crunch audit).
- New/changed controller: a controller spec asserting the route's auth posture
  (`@Public` vs guarded) and status/error contract via the metadata-reflection
  helper (`apps/api/src/common/testing/route-meta.ts`), plus any handler-owned
  behaviour (uniform-202 / 404-no-oracle / metadata-only / audit-field
  sanitisation). Services are faked — no DB.
- New tables: `tenant_id` + RLS policy.
- `make docs` passes: no broken link, unindexed document, malformed ADR,
  view register disagreeing with `views.dsl`, or cited requirement ID no
  document defines. Model or ADR touched: `make check` too.
- Security-relevant change: a short threat-model note under `docs/threat-models/`.
- No secrets; no banned log patterns.

## Pull request flow

- Every change lands via a PR; `main` is protected.
- **Self-review the full branch diff before opening the PR**: run one
  code-review pass over everything the branch changes (Claude Code:
  `/code-review` at medium effort; other agents: their equivalent review prompt)
  and fix the findings first. One pass per PR, not per edit — the domain
  reviewers (crypto / boundary / infra) still run after non-trivial changes in
  their areas, and the edit-time hooks and pre-commit gates cover the mechanical
  tier.
- **Every PR description is written for a non-programmer product owner**: a
  plain-language "what changed and why" plus a **"How to verify by hand"**
  section with concrete steps (what to click/run, what you should see). The
  owner reviews behavior, not diffs — this section is how. A PR whose effect
  can't be explained in product terms is a smell.
- **Every PR gets two equal reviews — Codex (`chatgpt-codex-connector`) and the
  `@claude` reviewer (`.github/workflows/claude.yml`) — and never merges on
  green CI alone.** Request both right after opening the PR: comment `@codex
  review`, and ping `@claude review this PR …` instructing it to apply the
  AGENTS.md review criteria and end with one line `VERDICT: PASS` or `VERDICT:
  FINDINGS`. Resolve **every finding from either reviewer** (treat P1/P2 like CI
  failures), or reply on the PR with an explicit, recorded justification. After
  any push, re-request both.
- **Check the aggregate verdict with `.claude/hooks/review-status.sh <pr>
  [--wait]`** — Codex may answer only with a 👍 reaction on the PR body (its
  no-findings signal), which reviews/comments queries and `gh pr view` do not
  show; the script reads every channel for both reviewers and reports them
  separately plus an aggregate. Exit codes: 0 clean (both verdicts in;
  `degraded: true` if Claude-only under a Codex usage limit — record that on the
  PR), 1 findings (from either), 2 a verdict still missing, 3 stale (a verdict
  predates the head commit — re-request, don't merge on it), 4 Codex over its
  usage limit with no Claude verdict yet, 5 unparseable Claude reply.
- If a reviewer stays silent after a re-request, a human decides; never merge unreviewed.
- Merge only when **both** hold: CI green (ci · security · codeql) **and** both
  reviews are addressed.

## Never do

- Weaken or bypass crypto, RLS, or auth "to make it work".
- Add a dependency without a one-line justification.
- Run `terraform apply`, `terraform destroy`, `az vm run-command`, `docker
  push`, or `git push --force` without explicit human confirmation.
- Print secret files (`.env`, `*.tfvars`, keys).
- Drive-by refactors. Keep diffs tight.

## Review criteria (apply the matching set after non-trivial changes)

**Crypto** (`packages/crypto`, keys, envelope): no hand-rolled crypto; server
stays crypto-blind; keys never logged/transmitted in clear; the device keystore
is sealed under the **WebAuthn-PRF** unlock key and **no recoverable secret is
ever stored server-side** (the Argon2id key-backup surface was removed — `0040`;
a lost passkey is a fresh start); CSPRNG only (no `Math.random`).

**Server boundary** (`apps/api`, queries, endpoints): no plaintext on the
server; `tenant_id` + RLS on every tenant table; tenant context not set from
unverified client input; no secrets/tokens/content in logs; authz on every path
(no IDOR); Zod-validated I/O; every route documented in the spec; every
controller has a spec pinning its guard + status contract.

**Infra** (`infra/`, workflows, Dockerfiles, `compose.yaml`): no secrets in
code; containers non-root + read-only FS + dropped caps + limits; data services
private (no public endpoints); least-privilege roles + **Managed Identity**
(VM); secrets delivered from **Key Vault** as files, never in env; CI uses OIDC
and never interpolates untrusted event input into `run:`; EU region pinned.

## Procedures

- **New DB table** → `tenant_id` + RLS policy + leading-`tenant_id` index.
  Content columns store ciphertext only.
- **Security-relevant feature** → write the threat-model note *before* coding;
  verify against the 6 invariants.
- **New/changed endpoint** → annotate with OpenAPI/Swagger (auth + tight typed
  schema), regenerate `apps/api/openapi.json`, run the 42Crunch audit.
  Add/extend the controller spec (two tiers: contract via `reflectRouteMeta`,
  behaviour via direct instantiation with faked services) so the route's
  `@Public`/guard posture and status contract are pinned.

## Enforcement is tool-agnostic

Whatever agent you are, these gates run on commit/push regardless — do not bypass them:

- **pre-commit** (lefthook): gitleaks, ESLint, Prettier, Semgrep (`.semgrep/`).
- **pre-push**: typecheck, tests.
- **CI**: Semgrep, OSV, Trivy, Checkov, gitleaks, 42Crunch audit, CodeQL,
  docs consistency (`make docs`); nightly DAST. (Kubescape dropped with K8s —
  deploy is a single VM via Docker Compose.)

## Architecture authoring

The kit comes from `architecture-base`. Apply **this** repository's evidence,
paths, pins and checks; never copy the base repo's fictional Payment Platform.

- Structurizr model and view work: read
  `.agents/skills/architecture-views/SKILL.md`.
- Architecture documentation beyond diagrams — requirements, assumptions, ADR
  history, data and integration concerns, risks, roadmap: read
  `.agents/skills/architecture-docs/SKILL.md`. Use both for a mixed request.
- **Before opening or updating any pull request**: read
  `.agents/skills/docs-sync/SKILL.md` and fix, in the same branch, every doc
  claim the branch falsified. `make docs` is its counted half — a green run
  means "nothing provably false", not "the docs are good".
- Use automatic layout and verify rendered readability. Export PNG/SVG by hand;
  do not add export automation unless asked.
- **Prose wraps at 80 columns**, enforced by `make docs`. Never use a Markdown
  formatter for it: mdformat and prettier both pad table cells to the widest
  column, making the longest line longer. Tables, fenced blocks, headings,
  image lines, YAML frontmatter and a line held long by one unbreakable token
  are exempt.
- `docs/architecture/overview/` is the only folder Structurizr imports and it
  does not recurse: one file is one page is one navigation entry. A register
  reaches the Documentation tab and the PDF by being **symlinked** into it as
  `NN-name.md`, staying authored once in its own folder. Keep every
  `![alt](embed:Key)` on ONE line — a wrapped embed drops the view into the
  appendix and still exits 0.
- Never title a document the same as the workspace: the PDF builder treats a
  matching first line as the cover and lifts that file's subheadings to top
  level.
- `docs/architecture/model/styles-shared.dsl` and the three files copied into
  `scripts/` stay unchanged; improve them in architecture-base first, then
  re-copy. A deliberate local divergence carries a `LOCAL CHANGE (report
  upstream)` comment saying why.

## Per-tool wiring

- **`AGENTS.md` and `CLAUDE.md` are byte-identical twins.** Edit `AGENTS.md`,
  then `cp AGENTS.md CLAUDE.md`; `make docs` fails when they drift. This
  replaces the previous `@AGENTS.md`-import arrangement, so that the shared
  `check_docs_consistency.py` needs no local patch. Everything in this file
  applies to whichever agent reads it — the Claude Code sections below are
  wiring, not a separate rule set.
- **Codex**: reads this file natively (merges `~/.codex/AGENTS.md` + repo
  `AGENTS.md`). Recommended `~/.codex/config.toml` and prompt files are in
  `.codex/` — see `docs/architecture/agent-portability.md`. Codex enforces the
  destructive-command boundary via its **sandbox + approval policy**, not
  per-command hooks.
- **Claude Code**: reads `CLAUDE.md`, the twin of this file, and adds subagents
  (`.claude/agents/`), skills (`.claude/skills/`) and hooks/permissions
  (`.claude/settings.json`). Agent and skill definitions carry YAML
  frontmatter that Claude Code parses — never rewrap it.

## Claude Code specifics

Everything above is the shared contract. This section adds only the
Claude-Code-specific tooling that serves it.

- **Subagents** (`.claude/agents/`), this repo's own: route through the matching
  reviewer after non-trivial changes — `crypto-reviewer` (crypto/keys/envelope),
  `security-boundary-auditor` (server boundary, RLS, logging, authz),
  `infra-reviewer` (Terraform / Docker Compose / systemd). Use
  `security-architect` proactively *before* coding anything that touches
  architecture, roadmap order, E2EE/protocol design, key management, or trust
  boundaries — get its plan, then implement on the session model.
- **Subagents imported from agent-base**: `silent-failure-hunter` (swallowed
  errors, bad fallbacks — the gap the four reviewers above do not cover),
  `type-design-analyzer` (encapsulation and invariants in types),
  `build-error-resolver` (build and type errors, minimal diffs),
  `comment-analyzer` (comment rot).
- **Skills** (`.claude/skills/`), this repo's own: `/db-migration`,
  `/feature-threat-model`, `/api-spec`, `/await-reviews`. From
  architecture-base: `/architecture-views`, `/architecture-docs`, `/docs-sync`.
  Plus built-ins `/security-review`, `/code-review`.
- **Skills imported from agent-base**: `/e2e-testing`, `/accessibility`,
  `/production-audit`, `/github-ops`, `/nestjs-patterns`, `/postgres-patterns`,
  `/docker-patterns`, `/react-patterns`, `/vite-patterns`. The last five carry
  an **"In this repository"** note recording where upstream assumes a different
  stack — Prisma, Supabase, Kubernetes, Next.js — and what this repo does
  instead. Read that note before following the body.
- **Vendored rules** (`.claude/rules/ecc/`): agent-base's TypeScript and React
  rule sets. `check_docs_consistency.py` excludes this directory by design, so
  they are reference material, not gated documentation.
- **Every skill is mirrored byte-for-byte into `.agents/skills/`**, and
  `make docs` fails when a mirror drifts. That mirror is what makes these
  usable by Codex and any other agent, which is the point of importing them
  rather than relying on a machine-local install.
- **A link inside a mirrored skill must resolve from both copies**, since the
  two are byte-identical. So a relative link is fine when its target is
  mirrored too — a file inside the same skill directory, or a sibling skill —
  and must be an **absolute URL** when it points anywhere else, such as
  `.claude/rules/ecc/`, which exists under `.claude/` only. `SELF_REPO` is set,
  so `check_self_links` verifies those absolute links resolve on disk.
- **Hooks + permissions** (`.claude/settings.json`): destructive-bash guard +
  edit-time invariant checks. Open `/hooks` once (or restart) to activate after
  a fresh clone.

### Model & effort routing (token budget)

The session default is set in `.claude/settings.json`: `opusplan` (Sonnet for
execution, Opus automatically in plan mode) at high effort. Escalation happens
through delegation, never by raising the main-session model:

- **Plan-mode gate — the trigger is the upcoming file edit, not whether the task
  "feels big".** Reading and investigating are free-form, but the moment a task
  is headed for a code change (any roadmap item, bug fix, feature, or refactor
  that will end in a PR), enter plan mode (Opus under `opusplan`) **before the
  first Edit/Write** — scouting the fix site, checking conventions, and sizing
  the change belong *inside* plan mode, not before it. Present the plan in plain
  language a non-programmer product owner can judge — what will change, what
  could break, how it gets verified — and get approval before any file is
  modified. If you catch yourself preparing an implementation without an
  approved plan, stop and enter plan mode immediately. Only trivial mechanical
  edits the user explicitly dictated (a typo, a one-line config value) skip the
  gate.
- Heavy reasoning is pinned where it belongs: every reviewer subagent
  (`security-architect`, `crypto-reviewer`, `security-boundary-auditor`,
  `infra-reviewer`) and the `/feature-threat-model` skill run **Opus at max
  effort**. Delegate to them instead of suggesting a model switch.
- **Deep reviews are scheduled, not continuous.** At milestones (finished
  roadmap phase, pre-beta), suggest a one-off `/code-review ultra` plus a
  full-surface `security-architect` pass. Per-PR: one `/code-review` (medium
  effort) pass over the branch diff before opening the PR, plus the pinned
  reviewers + Codex. Never per-edit — the hooks and pre-commit gates cover that
  tier.
- Never use or suggest `ultracode`, a Fable main session, or a `[1m]` context
  model unless the user explicitly asks — these burn the usage window.
- Stay frugal in the main loop: don't scan the whole repo when a targeted search
  works; prefer subagents (fresh, small context) for broad exploration.
- After a merged PR or a finished roadmap slice, suggest `/compact`.

These are Claude Code's own controls. The rules they serve live above, in
the sections every agent shares.

### Post-coding auto-flow

Once local gates pass (`pnpm -r typecheck && pnpm -r test`), run the full PR
flow **automatically — no pause, no confirmation needed**:

1. `/code-review` (medium effort) over the full branch diff → fix any must-fix
   findings → commit (Write tool for body file, `git commit -F`).
2. `git push -u origin <branch>`.
3. `gh pr create --body-file /tmp/pr-body.md` (Write tool for the body), then
   immediately post **both** review requests per the `/await-reviews` skill:
   `@codex review` plus the `@claude review …` ping with the `VERDICT:`
   contract.
4. **Watch CI**: `gh pr checks <pr> --watch` — if any job fails, immediately
   investigate (`gh run view … --log | grep -A20 Error`) and fix: new commit →
   push → wait for CI to re-run. Don't wait for the user to notice failures.
5. **Await both reviews**: `.claude/hooks/review-status.sh <pr> --wait` (blocks
   up to 15 min; aggregates Codex + Claude per the `/await-reviews` skill). If
   FINDINGS — from either reviewer — fix → push → re-request both → re-run.
6. **Only pause for `gh pr merge`** — that is the one outward, hard-to-reverse
   step the user drives explicitly.

Steps 4 and 5 run concurrently: start the CI watch, then in the same turn run
the review status check with `--wait`. Fix CI failures as they appear.
