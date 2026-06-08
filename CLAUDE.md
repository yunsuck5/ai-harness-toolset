# CLAUDE.md — ai-harness-toolset repo-local instructions (Claude Code)

Repo-local development instructions for working on the **ai-harness-toolset** repository itself, loaded by Claude Code from the repo root. This file is **not** the global managed-block snippet payload (`snippets/CLAUDE_SNIPPET.md`) and does **not** embed it — adopter-universal ai-harness invariants are delivered by the global managed block instead (see the shared body). It is **public-safe and tracked**. Everything from the shared-body marker down is byte-identical to `AGENTS.md`; only this header differs.

<!-- BEGIN SHARED BODY — byte-identical across CLAUDE.md and AGENTS.md; edit both together (see "Mirror-edit rule"). The header above is the only sanctioned per-tool divergence. -->

## What this file is

These are **repo-development** instructions for the `ai-harness-toolset` repo itself — a thin *docs trigger map* plus repo conventions and boundaries. They are **additive** to the global ai-harness instruction payload, not a copy of it:

- **Adopter-universal ai-harness invariants** (managed-block adoption discipline, hard boundaries, verdict vocabulary, ToolRoot/ProjectRoot topology, role/reviewer-mode) are delivered by the **global managed block** an operator adopts into their `%USERPROFILE%\.claude\CLAUDE.md` / Codex user-global `AGENTS.md` (source: `snippets/CLAUDE_SNIPPET.md` / `snippets/AGENTS_SNIPPET.md`). This file does **not** restate them and does **not** embed that block.
- **Where to read first** for any subsystem — the orientation / routing map — is `docs/**` and `docs/contracts/**`; this file only says **when to read which doc**, never duplicating doc bodies. These are read-first routing / context pointers, **not** active-behavior authority (per the *Final hard rule*). Start question→doc routing at `docs/current/REPO_READING_GUIDE.md`; placement at `docs/README.md`.
- **Skill discovery** (review / Brief workflows) is owned by each skill's own `description` (`snippets/claude-skills/ai-harness-review`, `snippets/claude-skills/ai-harness-brief`); this file is **not** a skill index, routing table, or trigger fallback.

## Docs trigger map

For each task class: *inspect first → validation/review gate → mutation boundary.* Pointers only — read the named doc for detail.

| Task class | Inspect first (read-first orientation) | Validation / review gate | Mutation boundary |
|---|---|---|---|
| **Review** subsystem | `docs/contracts/review/REVIEW_RESULT_CONTRACT.md`; `snippets/claude-skills/ai-harness-review/SKILL.md`; `docs/systems/review/STATUS.md` (if status changes) | Codex local-correctness + system-coherence; `review-verify -RequireResult` | review machinery is maintenance-mode; a verdict approves no commit/push |
| **Install / update / uninstall** | `INSTALL.md`; `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` (+ §8A activation surface); `docs/systems/install-update/STATUS.md` | relevant Pester lifecycle suites; `scripts/verify-ps1.ps1` | LTS; no global/user filesystem mutation without explicit approval |
| **Snippet** (global payload) | **Snippet shape + rules tiers — read-first orientation:** `docs/architecture/instruction-surface/GLOBAL_SNIPPET_HARD_MINIMIZATION_CORRECTIVE.md` — the snippet is a **2-H2 always-loaded bootstrap** (`## Safety floor` + `## Operating rules and topology`) backed by two rules tiers: global-distribution `snippets/rules/*.md` (installed) + repo-only `rules/*.md`. The whole distribution is `docs/`-free; review/Brief procedures stay in the deployed skills (discovered by description). **Migration history / evidence:** `GLOBAL_SNIPPET_FIRST_MIGRATION_DESIGN.md` + `GLOBAL_SNIPPET_FIRST_MIGRATION_PLAN.md` (keep-by-proof) · `INSTRUCTION_SURFACE_PLAN.md` + `GLOBAL_SNIPPET_RELOCATION_AUDIT.md` · `docs/systems/skills/FUNCTION_LEVEL_SKILL_ARCHITECTURE_PLAN.md` + `STATUS.md` (SK-06) | full Pester (`Invoke-Pester -Path .\tests`); Codex local-correctness + system-coherence | keep the snippet a minimal bootstrap and the distribution `docs/`-free — new content is an always-on invariant (snippet safety floor or `snippets/rules/`) or absorbed into a deployed skill / template / script (never a `docs/` pointer in a distributed file); **no** skill-routing pointers; keep CLAUDE/AGENTS snippet symmetry (vendor-specific destination wording aside) |
| **Brief** | `docs/contracts/brief/BRIEF_CONTRACT.md`; `snippets/claude-skills/ai-harness-brief/SKILL.md` | Codex review | do not change `brief-*.ps1` unless explicitly scoped |
| **Source / docs** | **active rule — read before placing / changing docs / closing out: `rules/docs-working-model.md`** (docs placement, top-down flow, single-home, STATUS/BACKLOG shape, on-demand briefing, two-level closeout gate); orientation/rationale only — `docs/README.md` (placement map), `docs/current/REPO_READING_GUIDE.md` (routing), `docs/policies/DOCS_OPERATING_MODEL.md` (why/record) | Codex review on the **corrected** working tree | a source/doc edit **after** a review makes that review stale — re-run |
| **PowerShell / script** | `docs/policies/POWERSHELL_POLICY.md`; `docs/policies/CLI_ENVIRONMENT_ASSUMPTIONS.md` | affected Pester + full suite; `scripts/verify-ps1.ps1` | see *Repo execution conventions* below; controlled IO via `scripts/lib/encoding.ps1` |
| **Repo-local instruction surface** (editing `CLAUDE.md` / `AGENTS.md`) | `docs/architecture/instruction-surface/REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md`; `docs/architecture/instruction-surface/GLOBAL_SNIPPET_RELOCATION_AUDIT.md` | Codex review; `tests/repo-local-instruction-parity.Tests.ps1` | edit the shared body of **both** files symmetrically (*Mirror-edit rule*); tracked = public-safe only |

## Repo execution conventions

Always-on for this repo (its canonical scripts are all `.ps1`). The repo-only file / output discipline is **collected in the repo-only rules tier `rules/powershell-and-file-encoding.md`** (rationale / derivation: `docs/policies/POWERSHELL_POLICY.md` + `docs/policies/CLI_ENVIRONMENT_ASSUMPTIONS.md` Tier 1). In short:

- **`.ps1` files must be UTF-8 with BOM + CRLF.** Run `scripts/verify-ps1.ps1` after creating or modifying any `.ps1`.
- **Native-exe output must keep stdout / stderr / exit code separate** — no `2>&1` / `Out-String` / `Out-Null` merged capture for correctness checks; under Windows PowerShell 5.1 with `$ErrorActionPreference = 'Stop'` a merged capture aborts before `$LASTEXITCODE` can be read.
- Other artifacts: `.md` / `.json` / `.txt` = UTF-8 **without** BOM + LF; controlled file IO uses `scripts/lib/encoding.ps1`.

The two rules tiers are distinct: **repo-only** rules live in `rules/` (this repo's development discipline, not distributed); **adopter-universal** rules ship in `snippets/rules/` under the `snippets/` payload root (`docs/architecture/instruction-surface/GLOBAL_SNIPPET_HARD_MINIMIZATION_CORRECTIVE.md`).

## Public-safe boundary

These files are **tracked** (public to any contributor), so they carry only public-safe repo guidance. **Never** put in them: secrets / tokens / credentials; personal or machine-specific paths or state; local model endpoints; session-restore state or `log/brief/BRIEF.md` contents; private handoff or user decision history; runtime evidence or `log/**` payloads. Durable pointers resolve only to git-tracked files or git history — never to `log/**`, `polishing/**`, or user/global files (durable-pointer rule: `rules/docs-working-model.md`, *Per-system STATUS.md shape / altitude*).

## Mirror-edit rule

`CLAUDE.md` and `AGENTS.md` share the body below the marker **byte-for-byte**; only the per-tool header above differs. **Any edit to the shared body must be applied to both files in the same change** — a single-file shared-body edit is an **asymmetry defect** (the same discipline the global snippets follow, `docs/architecture/instruction-surface/GLOBAL_SNIPPET_RELOCATION_AUDIT.md` §2). The parity check `tests/repo-local-instruction-parity.Tests.ps1` guards this.

## Non-goals (this repo-local surface)

- No `.claude/*` or `.codex/*` instruction surface. The repo-local instruction surfaces are the root `CLAUDE.md` / `AGENTS.md` plus the repo-only rules tier `rules/*.md` they point to (`docs/architecture/instruction-surface/REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md` §5; `docs/architecture/instruction-surface/GLOBAL_SNIPPET_HARD_MINIMIZATION_CORRECTIVE.md`).
- No `/init` (Claude or Codex) — these files are authored, not scaffolded.
- No hooks, no Codex Rules, no daemon / watcher / scheduler.
- **Memory is not a delivery surface** — nothing here depends on memory; all of it is tracked.
- No ToolRoot move (vendor-neutral ToolRoot is a separate decision surface — `docs/architecture/instruction-surface/INSTRUCTION_SURFACE_PLAN.md` §13).
- This file does **not** edit the global snippets. The two PowerShell rules live **only here** (the repo-local root files): **Track D removed them** from the global snippet (then in `## Other rules`), completing the Track C→D handoff (`docs/architecture/instruction-surface/REPO_LOCAL_INSTRUCTION_SURFACE_PLAN.md` §9; `docs/systems/skills/STATUS.md` SK-03). The snippet's `## Other rules` section was itself later removed by the hard-minimization corrective (`STATUS.md` SK-06; `docs/architecture/instruction-surface/GLOBAL_SNIPPET_HARD_MINIMIZATION_CORRECTIVE.md`), which moved the snippet's adopter-universal reusable rules to the global-distribution rules tier `snippets/rules/` and migrated these two PowerShell rules to the repo-only rules tier `rules/powershell-and-file-encoding.md` (still repo-development discipline, not adopter-universal — see *Repo execution conventions*). No Batch 3 / Batch 4 implementation here.

## Final hard rule — `docs/**` is not load-bearing authority

This is the **top-level interpretation rule** for all work in this repo, and it takes precedence over every section above. Wherever earlier framing appears to hand authority to a doc, read it through this rule: treat those as **read-first / inspection-routing pointers**, not a delegation of active-behavior authority to `docs/**`.

- **MUST NOT** treat anything under `docs/**` as the **load-bearing authority** for active behavior — functionality, runtime or workflow behavior, safety rules, review procedure, install / update / uninstall lifecycle behavior, managed-block mutation rules, or any operational decision. Those are governed by whichever **applicable active owner surface** actually defines the behavior — for example scripts, tests, templates, snippets, skills, `config/**`, the binding instructions in this root file, or the repo-only `rules/*.md` — never by a `docs/**` page. That list is illustrative, not a closed enumeration of the active surface: the boundary this rule draws is *`docs/**` vs. the binding active surface*, not membership in any fixed set.
- **MUST NOT** let a stale, narrative, status, or rationale doc **override** an active instruction or the actual runtime behavior. When a `docs/**` page disagrees with the code, tests, or instructions in force, the active surface wins and the doc is the thing that is wrong.
- The toolset's core behavior **must stay operational even if `docs/**` were absent**: `docs/**` is never a runtime dependency, a validation authority, or a routing authority. Reading a doc may aid understanding or restoration, but the active surface (e.g., scripts, templates, snippets, skills, `rules`, `config`, tests) must function without requiring any `docs/**` page.
- **MAY** use `docs/**` freely for explanation, history, decision record, rationale, and status tracking, and **MAY** read a doc to learn *where* something lives or *why* a decision was made. That is inspection and context, not authority delegation. This rule is **not** "do not read docs," "delete docs," "strip every docs reference," or "docs are useless," and it is **not** a license to redefine the active-owner surfaces in one sweep.
- If you find a structure that **forces** `docs/**` to be read as authority to carry out a function, behavior, or rule — i.e., a binding behavior whose only definition lives in a `docs/**` page — that is **not** a "just follow the doc" situation. It is a defect and a **separate correction target**: report it as a finding and relocate the load-bearing content to the active surface under its own scoped change. Do not silently obey it.

<!-- END SHARED BODY -->
