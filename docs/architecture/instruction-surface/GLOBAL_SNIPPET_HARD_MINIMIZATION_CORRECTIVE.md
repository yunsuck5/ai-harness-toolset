# Global Snippet Hard Minimization — Corrective (per-item disposition record)

**Status: implemented corrective record.** This documents the corrective that took the global snippet from a *compact policy bundle* to a *minimal bootstrap*, introduced a **two-tier rules architecture**, and made the **entire global distribution self-contained** (no `docs/` dependency). It is the per-item classification record required by the corrective direction and the current authority for the snippet's shape and the rules tiers.

## The two-tier rules architecture (user-directed)

The relationship is the one Claude Code's `CLAUDE.md` has to its rules tier: a small always-loaded bootstrap plus a rules layer it points to.

- **Global-distribution rules tier — `snippets/rules/*.md`.** Ships with the toolset because it sits under the `snippets/` payload root (`scripts/lib/install-pipeline-core.ps1` `$InstallPipelinePayloadRoots` = `config` / `scripts` / `snippets` / `templates`), so it installs to `<ToolRoot>/snippets/rules/`. It holds the reusable, adopter-universal, always-on operating rules that are **not absorbed** into a skill, template, or script. **One rule group per file.** Self-contained (no `docs/` dependency). The snippet points here.
- **Repo-only rules tier — `<repo-root>/rules/*.md`.** Repository-development rules for this repo itself; **not** distributed (not under a payload root). The repo-development root `CLAUDE.md` / `AGENTS.md` point here. **One rule group per file.**
- **Rules never live in `docs/`.** `docs/` is rationale / design / contract, source-repo only, never a runtime dependency of a distributed file.

This **supersedes the GSF-B3 decision** "create no rules surface now" (`GLOBAL_SNIPPET_FIRST_GSF_B3_RULES_LOADING_DECISION.md` §1): the user directed the two rules tiers. GSF-B3's loading **model** (rules are not auto-loaded; they are instructed-read; truly-always-on safety stays in the bootstrap) is retained and followed. No `.claude/rules/`, `.codex/rules/`, or `@import` is introduced (those remain out of scope).

## The self-containment constraint (user-directed)

The global distribution = `config` / `scripts` / `snippets` / `templates`. **`docs/` is not installed.** So every distributed surface — the snippet, `snippets/rules/`, the deployed skills under `snippets/claude-skills/`, and the templates — must operate without any `docs/` dependency. This corrective removed every `docs/` runtime reference from those surfaces (the only remaining `docs/` mentions in distributed files are self-descriptions like "not in `docs/`" and the generic English phrase "docs/code").

## What it supersedes (objective-completion framing only)

The prior "Global Snippet First" sequence (GSF-B1…B4) declared itself "**complete with intentional residuals**" but left an 8-section compact policy bundle that still routed to `docs/`. That was a *procedural* closeout, not the objective. Those GSF records remain valid **as evidence / history**; their objective-completion claim is superseded here (`GLOBAL_SNIPPET_FIRST_MIGRATION_PLAN.md` §2 / Stage flow; `GLOBAL_SNIPPET_FIRST_GSF_B2_CLASSIFICATION.md`; `docs/current/SOURCE_OF_TRUTH.md` Q10/Q11).

**Authority basis.** The corrective direction note + the user `/goal` + the user's two follow-up constraints: (1) the global distribution cannot reference `docs/`; absorb skill content into skills; compose snippet / scripts / templates around the distribution; (2) the rules tiers are `snippets/rules/` (global, distributed) and `<repo-root>/rules/` (repo-only), holding what is not absorbed into skill / template / script, one rule group per file.

**Hard boundaries honored.** Symmetric snippet edit (vendor-specific intro / destination aside); no runtime / install / update / uninstall / ToolRoot / skill-procedure semantic change; **no payload-root change** (`snippets/rules/` works because `snippets/` is already a payload root); no `.claude/` / `.codex/` / `@import`; no hook/daemon; no global/user file mutation; no commit/push (separate explicit approval).

---

## 1. Before / after snippet shape

| | Before (HEAD `df123fa`) | After |
|---|---|---|
| H2 sections | **8** — Adoption destination · Adoption rules · Role neutrality · Project layout · Result verdict vocabulary · Operator stance · Forbidden in this toolset · Other rules | **2** — Safety floor · Operating rules and topology |
| Character | compact policy bundle, routed to `docs/**` | always-loaded bootstrap: critical safety floor inline + pointer to the distributed rules tier |
| External dependency | `docs/**` pointers | **none** — no `docs/` or non-distributed pointer; points to `<ToolRoot>/snippets/rules/` (distributed) |
| Skill mention | named/routed indirectly | none — skills are discovered by their own `description`; the bootstrap neither names nor routes to them |
| Symmetry | parallel, vendor-specific differences | parallel; only H1, intro tool-name, and the Destination bullet differ |

After: H1 (test-bound) + intro + `## Safety floor` (managed-block-only, approval gates, destinations — 3 bullets) + `## Operating rules and topology` (pointer to `<ToolRoot>/snippets/rules/*.md` + ToolRoot channel order + `log/` partitioning).

---

## 2. Per-item disposition

Disposition: **bootstrap** (kept inline in the snippet safety floor) · **rules tier** (moved to `snippets/rules/<file>.md`, distributed) · **skill** (owned by a deployed skill) · **removed**.

| Before snippet item | Disposition | Where it lives now |
|---|---|---|
| H1 | **bootstrap** | snippet (test-bound: `apply-managed-block.Tests.ps1` `AC-AMB-HAPPY-2`) |
| Intro | **bootstrap** (compressed) | snippet — identity + role-neutral clause + "skills discovered by description, bootstrap does not route" |
| Adoption destination (paths + forbidden `%USERPROFILE%\.claude\AGENTS.md`) | **bootstrap** | snippet `## Safety floor` Destination bullet (vendor-specific) |
| Adoption rules (managed-block only, no whole-file overwrite, fail-fast markers, separate approval boundaries) | **bootstrap** (core) + **rules tier** (detail) | snippet `## Safety floor` (core) + `snippets/rules/global-file-mutation-boundary.md` (detail); deterministic guard = `scripts/apply-managed-block.ps1` + `scripts/lib/managed-block.ps1` + tests |
| Role neutrality (loads regardless of role) | **bootstrap** (one clause) | snippet intro |
| Role neutrality (reviewer/auditor binding; reviewer skips Brief) | **skill** | `ai-harness-review` + `ai-harness-brief` skills (reviewer-mode exclusion inline) |
| Project layout (ToolRoot/ProjectRoot/log topology + channel order) | **bootstrap** | snippet `## Operating rules and topology` |
| Project layout (full ToolRoot resolution; reviewer config; review-record layout) | **skill** | `ai-harness-review` skill step 1 + the record layout inline; `config/reviewer.json` |
| Result verdict vocabulary (values + meanings + next-action) | **skill** | `ai-harness-review` skill steps 6–7 |
| Result verdict vocabulary (verdict approves nothing) | **bootstrap** + **rules tier** | snippet approval-gates bullet + `snippets/rules/repository-change-safety.md` |
| Operator stance (stay in scope; stop/report; retraction) | **skill** | `ai-harness-review` skill step 7 |
| Forbidden — no per-user partitioning / `BF_STATE.json` / daemon / hook / background | **rules tier** | `snippets/rules/no-background-or-hidden-state.md` |
| Forbidden — no implicit/whole-file global-file mutation (+ paths, managed-block exception, no auto-create `~/.claude` `~/.codex`) | **bootstrap** (core) + **rules tier** (detail) | snippet `## Safety floor` + `snippets/rules/global-file-mutation-boundary.md` |
| Forbidden — no creation of `%USERPROFILE%\.claude\AGENTS.md` | **bootstrap** | snippet Destination bullet |
| Forbidden — no automatic `.gitignore` mutation | **rules tier** | `snippets/rules/repository-change-safety.md` |
| Other rules — commit/push require explicit approval | **bootstrap** (core) + **rules tier** (detail) | snippet approval-gates bullet + `snippets/rules/repository-change-safety.md` |
| Other rules — temporary-file hygiene | **rules tier** | `snippets/rules/repository-change-safety.md` |

---

## 3. Rules tiers created

**Global (distributed) — `snippets/rules/`:**
- `README.md` — tier index + the snippet↔rules-tier relationship + loading model.
- `global-file-mutation-boundary.md` — global/user instruction-file mutation boundary + managed-block adoption contract (self-contained; deterministic guard = `apply-managed-block.ps1` + `managed-block.ps1` + tests).
- `no-background-or-hidden-state.md` — no daemon/watcher/scheduler/hook/background; no sidecar state file; no per-user partitioning/ownership metadata.
- `repository-change-safety.md` — commit/push explicit approval; verdict approves nothing; no auto-`.gitignore`; temp-file hygiene.

**Repo-only (not distributed) — `<repo-root>/rules/`:**
- `README.md` — repo-only tier index + the two-tier distinction.
- `powershell-and-file-encoding.md` — `.ps1` UTF-8 BOM+CRLF + `verify-ps1`, native-exe stdout/stderr/exit separation, `.md`/`.json`/`.txt` UTF-8 no-BOM + LF. Migrated out of the root `CLAUDE.md` / `AGENTS.md` "Repo execution conventions" (which now point here).

## 4. Distribution made docs-free (SC fix)

- **Snippet:** no `docs/` or `rules/` (repo-root) pointer; points to `<ToolRoot>/snippets/rules/` (distributed).
- **`ai-harness-brief/SKILL.md`:** the load-bearing heading-set deferral to `docs/contracts/brief/BRIEF_CONTRACT.md` ("does not restate them") replaced — the minimal heading set is now stated inline and tied to the distributed `templates/brief/BRIEF.md` + `scripts/brief-check.ps1`; the docs "Authoritative references" section replaced with distributed source-side surfaces.
- **`ai-harness-review/SKILL.md`:** the `docs/**` "policy home" pointers (reference-sweep, reviewer-config category, result.md dual-authorship) reframed to the inline procedure / distributed `config/reviewer.json`.
- **`templates/review-input.md` + `templates/review-result.md`:** every `docs/contracts/review/REVIEW_RESULT_CONTRACT.md` / `docs/policies/REVIEWER_CONFIG_POLICY.md` "source-of-truth" pointer reframed to the inline shape / the `ai-harness-review` skill / `config/reviewer.json`.

## 5. Owner surfaces created / updated

- **Created:** `snippets/rules/` (4 files); `<repo-root>/rules/` (2 files); this record.
- **Snippet + skills + templates:** reduced / made docs-free as above.
- **Stale-corrected:** `GLOBAL_SNIPPET_FIRST_MIGRATION_PLAN.md` §2/Stage-flow; `GLOBAL_SNIPPET_FIRST_GSF_B3_RULES_LOADING_DECISION.md` (no-rules conclusion superseded; model retained); `GLOBAL_SNIPPET_FIRST_GSF_B2_CLASSIFICATION.md`; `docs/current/SOURCE_OF_TRUTH.md` Q10/Q11; `docs/systems/skills/STATUS.md` (SK-06); `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` §4; `docs/architecture/README.md`.
- **Dangling-reference fixes:** `README.md`; `docs/decisions/GLOBAL_ADOPTION_DECISION.md`; `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md`; root `CLAUDE.md` / `AGENTS.md` (Snippet trigger row + Track D note + Repo-execution-conventions + Non-goals, mirror-edited).

A reviewer verdict on this corrective approves no commit/push — those remain explicit user decisions.
