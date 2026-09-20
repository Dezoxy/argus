# Agent Portability — Codex, Claude Code, and others

argus is agent-neutral. The **rules** live in one file (`AGENTS.md`); the **hard
guarantees** live in git hooks + CI, which run no matter which agent (or human)
writes the code.

## One source of truth

```
AGENTS.md                  <- canonical contract (read natively by Codex, Cursor, Gemini CLI, …)
CLAUDE.md                  <- byte-identical twin, read by Claude Code
```

Edit **`AGENTS.md`**, then `cp AGENTS.md CLAUDE.md`. `make docs` fails when the
two drift, so the copy cannot be forgotten.

**This used to be an import.** `CLAUDE.md` was a one-line `@AGENTS.md` plus a
Claude-only section, which kept the rules in exactly one place. Adopting
`architecture-base` changed it: that kit's documentation gate requires the two
files to be byte-identical, and satisfying the rule was preferred over patching
the shared `check_docs_consistency.py`, which every repository built from the
kit copies unchanged.

The trade is real and worth stating. Claude-specific wiring — subagents, model
routing, the plan-mode gate — now also sits in the file Codex reads. It is
clearly fenced under a "Claude Code specifics" heading, and nothing in it
contradicts the shared rules; an agent that is not Claude Code simply has no
`.claude/` directory to apply it to.

## What's portable vs. tool-specific

| Capability | Claude Code | Codex | Portable? |
|---|---|---|---|
| Rules / contract | CLAUDE.md | AGENTS.md | ✅ byte-identical twins, gated by `make docs` |
| Review checklists | subagents (`.claude/agents/`) | "Review criteria" section in AGENTS.md | ✅ as guidance |
| Procedures (RLS migration, threat model, api-spec) | skills (`.claude/skills/`) | prompts (`.codex/prompts/`) | ✅ mirrored |
| Architecture authoring | skills (`.claude/skills/`) | same files under `.agents/skills/` | ✅ byte-identical mirror, gated by `make docs` |
| Stack know-how (NestJS, Postgres, Docker, React, Vite, E2E, a11y) | skills imported from agent-base | same files under `.agents/skills/` | ✅ byte-identical mirror; imported rather than left machine-local precisely so Codex gets them too |
| Destructive-command boundary | PreToolUse hooks + permissions (`.claude/settings.json`) | `approval_policy` + `sandbox_mode` (`~/.codex/config.toml`) | ⚠️ different mechanism, same outcome |
| **Hard enforcement** | — | — | ✅ **lefthook + CI, identical for both** |

The bottom row is the point: secrets scanning, lint, Semgrep, typecheck, tests
(pre-commit/pre-push via lefthook) and the full CI security suite gate **every**
commit regardless of agent. That's the real guarantee — the per-agent guardrails
just catch issues earlier.

## Set up Codex

```bash
# 1. AGENTS.md is already read automatically from the repo root — nothing to do.

# 2. Recommended global config (approval + sandbox = the boundary):
cp .codex/config.toml.example ~/.codex/config.toml   # then merge with any existing config

# 3. (Optional) expose the procedures as /db-migration, /feature-threat-model, /api-spec:
ln -s "$PWD/.codex/prompts/"*.md ~/.codex/prompts/
```

Key Codex settings (in `~/.codex/config.toml`): `approval_policy = "on-request"`
and `sandbox_mode = "workspace-write"` with `network_access = false` — together
these require human approval before the destructive/networked commands that
`AGENTS.md` lists, mirroring Claude Code's deny/ask hooks.

## Set up Claude Code

CLAUDE.md, `.claude/agents`, `.claude/skills`, and `.claude/settings.json` are
committed. After a fresh clone, open `/hooks` once (or restart) so the
mid-session-added hooks activate.

## Both tools, always

```bash
pnpm install      # Node deps (isolated in node_modules)
make tools        # Python scanners (isolated in .venv)
pnpm prepare      # installs lefthook git hooks (needs a git repo)
```
